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
      
      # There are three possible ways to use this method.  First, if you have a named route, 
      # you can specify the route as the first parameter as a symbol and any paramters in a 
      # hash.  Second, you can generate the default route by just passing the params hash, 
      # just passing the params hash.  Finally, you can use the anonymous parameters.  This 
      # allows you to specify the parameters to a named route in the order they appear in the 
      # router.  
      #
      # ==== Parameters(Named Route)
      # name<Symbol>:: 
      #   The name of the route. 
      # args<Hash>:: 
      #   Parameters for the route generation.
      #
      # ==== Parameters(Default Route)
      # args<Hash>:: 
      #   Parameters for the route generation.  This route will use the default route. 
      #
      # ==== Parameters(Anonymous Parameters)
      # name<Symbol>::
      #   The name of the route.  
      # args<Array>:: 
      #   An array of anonymous parameters to generate the route
      #   with. These parameters are assigned to the route parameters
      #   in the order that they are passed.
      #
      # ==== Returns
      # String:: The generated URL.
      #
      # ==== Examples
      # Named Route
      #
      # Merb::Router.prepare do
      #   match("/articles/:title").to(:controller => :articles, :action => :show).name("articles")
      # end
      #
      # url(:articles, :title => "new_article")
      #
      # Default Route
      #
      # Merb::Router.prepare do
      #   default_routes
      # end
      #
      # url(:controller => "articles", :action => "new")
      #
      # Anonymous Paramters
      #
      # Merb::Router.prepare do
      #   match("/articles/:year/:month/:title").to(:controller => :articles, :action => :show).name("articles")
      # end
      #
      # url(:articles, 2008, 10, "test_article")
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
      
      # Add functionality to the router. This can be in the form of
      # including a new module or directly defining new methods.
      #
      # ==== Parameters
      # &block<Block>::
      #   A block of code used to extend the route builder with. This
      #   can be including a module or directly defining some new methods
      #   that should be available to building routes.
      #
      # ==== Example
      # Merb::Router.extensions do
      #   def domain(name, domain, options={}, &block)
      #     match(:domain => domain).namespace(name, :path => nil, &block)
      #   end
      # end
      #
      # In this case, a method 'domain' will be available to the route builder
      # which will create namespaces around domains instead of path prefixes.
      #
      # This can then be used as follows.
      #
      # Merb::Router.prepare do
      #   domain(:admin, "my-admin.com") do
      #     # ... routes come here ...
      #   end
      # end
      # ---
      # @api public
      def extensions(&block)
        Router::Behavior.class_eval(&block)
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
