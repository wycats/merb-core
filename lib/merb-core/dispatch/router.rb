require 'merb-core/dispatch/router/cached_proc'
require 'merb-core/dispatch/router/behavior'
require 'merb-core/dispatch/router/route'
require 'merb-core/controller/mixins/responder'
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
    SEGMENT_REGEXP = /(:([a-z_][a-z0-9_]*|:))/
    SEGMENT_REGEXP_WITH_BRACKETS = /(:[a-z_]+)(\[(\d+)\])?/
    JUST_BRACKETS = /\[(\d+)\]/
    PARENTHETICAL_SEGMENT_STRING = "([^\/.,;?]+)".freeze

    @@named_routes = {}
    @@routes = []
    @@compiler_mutex = Mutex.new
    cattr_accessor :routes, :named_routes

    class << self
      # Finds route matching URI of the request and
      # returns a tuple of [route index, route params].
      #
      # ==== Parameters
      # request<Merb::Request>:: request to match.
      #
      # ==== Returns
      # <Array(Integer, Hash)::
      #   Two-tuple: route index and route parameters. Route
      #   parameters are :controller, :action and all the named
      #   segments of the route.
      def route_for(request)
        index, params = match(request)
        route = routes[index] if index
        if !route
          raise ControllerExceptions::NotFound, 
            "No routes match the request: #{request.uri}"
        end
        [route, params]
      end
      
      # Clear all routes.
      def reset!
        self.routes, self.named_routes = [], {}
      end

      # Appends the generated routes to the current routes.
      #
      # ==== Parameters
      # &block::
      #   A block that generates new routes when yielded a new Behavior.
      def append(&block)
        prepare(@@routes, [], &block)
      end

      # Prepends the generated routes to the current routes.
      #
      # ==== Parameters
      # &block::
      #   A block that generates new routes when yielded a new Behavior.
      def prepend(&block)
        prepare([], @@routes, &block)
      end

      # Prepares new routes and adds them to existing routes.
      #
      # ==== Parameters
      # first<Array>:: An array of routes to add before the generated routes.
      # last<Array>:: An array of routes to add after the generated routes.
      # &block:: A block that generates new routes.
      #
      # ==== Block parameters (&block)
      # new_behavior<Behavior>:: Behavior for child routes.
      def prepare(first = [], last = [], &block)
        @@routes = []
        yield Behavior.new({}, { :action => 'index' }) # defaults
        @@routes = first + @@routes + last
        compile
      end

      # Capture any new routes that have been added within the block.
      #
      # This utility method lets you track routes that have been added;
      # it doesn't affect how/which routes are added.
      #
      # &block:: A context in which routes are generated.
      def capture(&block)
        routes_before, named_route_keys_before = self.routes.dup, self.named_routes.keys
        yield
        [self.routes - routes_before, self.named_routes.except(*named_route_keys_before)]
      end

      # ==== Returns
      # String:: A routing lambda statement generated from the routes.
      def compiled_statement
        @@compiler_mutex.synchronize do
          @@compiled_statement = "def match(request)\n"
          @@compiled_statement << "  params = request.params\n"
          @@compiled_statement << "  cached_path = request.path\n  cached_method = request.method.to_s\n  "
          @@routes.each_with_index { |route, i| @@compiled_statement << route.compile(i == 0) }
          @@compiled_statement << "  else\n    [nil, {}]\n"
          @@compiled_statement << "  end\n"
          @@compiled_statement << "end"
        end
      end

      # Defines the match function for this class based on the
      # compiled_statement.
      def compile
        puts "compiled route: #{compiled_statement}" if $DEBUG
        eval(compiled_statement, binding, "Generated Code for Router#match(#{__FILE__}:#{__LINE__})", 1)
      end

      # Generates a URL based on passed options.
      #
      # ==== Parameters
      # name<~to_sym, Hash>:: The name of the route to generate.
      # params<Hash, Fixnum, Object>:: The params to use in the route generation.
      # fallback<Hash>:: Parameters for generating a fallback URL.
      #
      # ==== Returns
      # String:: The generated URL.
      #
      # ==== Alternatives
      # If name is a hash, it will be merged with params and passed on to
      # generate_for_default_route along with fallback.
      def generate(name, params = {}, fallback = {})
        params.reject! { |k,v| v.nil? } if params.is_a? Hash
        if name.is_a? Hash
          name.reject! { |k,v| v.nil? }
          return generate_for_default_route(name.merge(params), fallback)
        end
        name = name.to_sym
        unless @@named_routes.key? name
          raise "Named route not found: #{name}"
        else
          @@named_routes[name].generate(params, fallback)
        end
      end

      # Generates a URL based on the default route scheme of
      # "/:controller/:action/:id.:format".
      #
      # ==== Parameters
      # params<Hash>::
      #   The primary parameters to create the route from (see below).
      # fallback<Hash>:: Fallback parameters. Same options as params.
      #
      # ==== Options (params)
      # :controller<~to_s>:: The controller name. Required.
      # :action<~to_s>:: The action name. Required.
      # :id<~to_s>:: The ID for use in the action.
      # :format<~to_s>:: The format of the preferred response.
      #
      # ==== Returns
      # String:: The generated URL.
      def generate_for_default_route(params, fallback)
        query_params = params.reject do |k,v|
          [:controller, :action, :id, :format, :fragment].include?(k.to_sym)
        end

        controller = params[:controller] || fallback[:controller]
        raise "Controller Not Specified" unless controller
        url = "/#{controller}"

        if params[:action] || params[:id] || params[:format] || !query_params.empty?
          action = params[:action] || fallback[:action]
          raise "Action Not Specified" unless action
          url += "/#{action}"
        end
        if params[:id]
          url += "/#{params[:id]}"
        end
        if format = params[:format]
          format = fallback[:format] if format == :current
          url += ".#{format}"
        end
        unless query_params.empty?
          url += "?" + Merb::Request.params_to_query_string(query_params)
        end
        if params[:fragment]
          url += "##{params[:fragment]}"
        end
        url
      end
    end # self

  end
end
