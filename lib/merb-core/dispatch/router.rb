require 'merb-core/dispatch/router/cached_proc'
require 'merb-core/dispatch/router/behavior'
require 'merb-core/dispatch/router/route'
require 'merb-core/controller/mixins/responder'
module Merb
  class Router
    SEGMENT_REGEXP = /(:([a-z_][a-z0-9_]*|:))/
    SEGMENT_REGEXP_WITH_BRACKETS = /(:[a-z_]+)(\[(\d+)\])?/
    JUST_BRACKETS = /\[(\d+)\]/
    PARENTHETICAL_SEGMENT_STRING = "([^\/.,;?]+)".freeze
    
    @@named_routes = {}
    @@routes = []
    cattr_accessor :routes, :named_routes
    
    class << self

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

      # ==== Returns
      # String:: A routing lambda statement generated from the routes.
      def compiled_statement
        @@compiled_statement = "def match(request)\n"
        @@compiled_statement << "  params = request.params\n"
        @@compiled_statement << "  cached_path = request.path\n  cached_method = request.method.to_s\n  "
        @@routes.each_with_index { |route, i| @@compiled_statement << route.compile(i == 0) }
        @@compiled_statement << "  else\n    [nil, {}]\n"
        @@compiled_statement << "  end\n"
        @@compiled_statement << "end"
      end

      # Defines the match function for this class based on the
      # compiled_statement.
      def compile
        puts "compiled route: #{compiled_statement}" if $DEBUG
        eval(compiled_statement, binding, __FILE__, __LINE__)
      end

      # Generates a URL based on passed options.
      #
      # ==== Parameters
      # name<~to_sym, Hash>:: The name of the route to generate.
      # params<Hash>:: The params to use in the route generation.
      # fallback<Hash>:: Parameters for generating a fallback URL.
      #
      # ==== Returns
      # String:: The generated URL.
      #
      # ==== Alternatives
      # If name is a hash, it will be merged with params and passed on to
      # generate_for_default_route along with fallback.
      def generate(name, params = {}, fallback = {})
        if name.is_a? Hash
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
          [:controller, :action, :id, :format].include?(k.to_sym)
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
        url
      end
    end # self
    
  end
end