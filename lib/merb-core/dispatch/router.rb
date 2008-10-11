require 'merb-core/dispatch/router/cached_proc'
require 'merb-core/dispatch/router/behavior'
require 'merb-core/dispatch/router/resources'
require 'merb-core/dispatch/router/route'

module Merb
  # Router stores route definitions and finds the first
  # route that matches the incoming request URL.
  # 
  # Then information from route is used by dispatcher to
  # call action on the controller.
  # 
  # ==== Routes compilation.
  # 
  # The most interesting method of Router (and heart of
  # route matching machinery) is match method generated
  # on the fly from routes definitions. It is called routes
  # compilation. Generated match method body contains
  # one if/elsif statement that picks the first matching route
  # definition and sets values to named parameters of the route.
  # 
  # Compilation is synchronized by mutex.
  class Router
    @routes          = []
    @named_routes    = {}
    @resource_routes = {}
    @compiler_mutex  = Mutex.new
    @root_behavior   = Behavior.new.defaults(:action => "index")
    
    # Raised when route lookup fails.
    class RouteNotFound < StandardError; end;
    # Raised when parameters given to generation
    # method do not match route parameters.
    class GenerationError < StandardError; end;
    class NotCompiledError < StandardError; end;
    
    class << self
      # @private
      attr_accessor :routes, :named_routes, :resource_routes, :root_behavior
      
      # Creates a route building context and evaluates the block in it. A
      # copy of +root_behavior+ (and instance of Behavior) is copied as
      # the context.
      # 
      # ==== Parameters
      # first<Array>::
      #   An array containing routes that should be prepended to the routes
      #   defined in the block.
      # last<Array>::
      #   An array containing routes that should be appended to the routes
      #   defined in the block.
      # 
      # ==== Returns
      # Merb::Router::
      #   Returns self to allow chaining of methods.
      # 
      # @api public
      def prepare(first = [], last = [], &block)
        @routes = []
        root_behavior._with_proxy(&block)
        @routes = first + @routes + last
        compile
        self
      end
      
      # Appends route in the block to routing table.
      # 
      # @api public
      def append(&block)
        prepare(routes, [], &block)
      end
      
      # Prepends routes in the block to routing table.
      # 
      # @api public
      def prepend(&block)
        prepare([], routes, &block)
      end
      
      # Clears the routing table. Route generation and request matching
      # won't work anymore until a new routing table is built.
      # 
      # @api private
      def reset!
        class << self
          alias_method :match, :match_before_compilation
        end
        self.routes, self.named_routes = [], {}
      end
      
      # Finds route matching URI of the request and returns a tuple of
      # [route index, route params]. This method is called by the
      # dispatcher and isn't as useful in applications.
      # 
      # ==== Parameters
      # request<Merb::Request>:: request to match.
      # 
      # ==== Returns
      # Array[Integer, Hash]::
      #   Two-tuple: route index and route parameters. Route parameters
      #   are :controller, :action and all the named segments of the route.
      # 
      # @api private
      def route_for(request) #:nodoc:
        index, params = match(request)
        route = routes[index] if index
        if !route
          raise ControllerExceptions::NotFound, 
            "No routes match the request: #{request.uri}"
        end
        [route, params]
      end
      
      # A placeholder for the compiled match method.
      # 
      # ==== Notes
      # This method is aliased as +match+ but this method gets overridden with
      # the actual +match+ method (generated from the routes definitions) after
      # being compiled. This method is only ever called before routes are
      # compiled.
      # 
      # ==== Raises
      # NotCompiledError:: routes have not been compiled yet.
      # 
      # @api private
      def match_before_compilation(request) #:nodoc:
        raise NotCompiledError, "The routes have not been compiled yet"
      end
      
      alias_method :match, :match_before_compilation
      
      # Generates a URL from the params
      # 
      # ==== Parameters
      # name<Symbol>::
      #   The name of the route to generate
      # 
      # anonymous_params<Object>::
      #   An array of anonymous parameters to generate the route
      #   with. These parameters are assigned to the route parameters
      #   in the order that they are passed.
      # 
      # params<Hash>::
      #   Named parameters to generate the route with.
      # 
      # defaults<Hash>::
      #   A hash of default parameters to generate the route with.
      #   This is usually the request parameters. If there are any
      #   required params that are missing to generate the route,
      #   they are pulled from this hash.
      # 
      # ==== Example
      #   url(:edit_node, node.id, :foo => "bar")
      #   url(:edit_site_rating, site.id, rating.id, :foo => "bar")
      # 
      # ==== Returns
      # String:: The generated URL
      # 
      # @api private
      def url(name, *args)
        unless name.is_a?(Symbol)
          args.unshift(name)
          name = :default
        end
        
        unless route = Merb::Router.named_routes[name]
          raise Merb::Router::GenerationError, "Named route not found: #{name}"
        end
        
        defaults = args.pop
        
        route.generate(args, defaults)
      end
      
      # Generates a URL from the resource(s)
      # 
      # ==== Parameters
      # resources<Symbol,Object>::
      #   The identifiers for the resource route to generate. These
      #   can either be symbols or objects. Symbols denote resource
      #   collection routes and objects denote the members.
      # 
      # params<Hash>::
      #   Any extra parameters needed to generate the route.
      # ==== Returns
      # String:: The generated URL
      # 
      # @api private
      def resource(*args)
        defaults = args.pop
        options  = extract_options_from_args!(args) || {}
        key      = []
        params   = []
        
        args.each do |arg|
          if arg.is_a?(Symbol) || arg.is_a?(String)
            key << arg.to_s
          else
            key << arg.class.to_s
            params << arg
          end
        end
        
        params << options
        
        unless route = Merb::Router.resource_routes[key]
          raise Merb::Router::GenerationError, "Resource route not found: #{args.inspect}"
        end
        
        route.generate(params, defaults)
      end
      
      private
      
      # Compiles the routes and creates the +match+ method.
      # 
      # @api private
      def compile
        if routes.any?
          eval(compiled_statement, binding, "Generated Code for Router", 1)
        else
          reset!
        end
      end
      
      # Generates the method for evaluation defining a +match+ method to match
      # a request with the defined routes.
      # 
      # @api private
      def compiled_statement
        @compiler_mutex.synchronize do
          condition_keys, if_statements = Set.new, ""
          
          routes.each_with_index do |route, i|
            route.freeze
            route.conditions.keys.each { |key| condition_keys << key }
            if_statements << route.compiled_statement(i == 0)
          end
          
          statement =  "def match(request)\n"
          statement << condition_keys.inject("") do |cached, key|
            cached << "  cached_#{key} = request.#{key}.to_s\n"
          end
          statement <<    if_statements
          statement << "  else\n"
          statement << "    [nil, {}]\n"
          statement << "  end\n"
          statement << "end"
        end
      end
      
    end # class << self
  end
end
