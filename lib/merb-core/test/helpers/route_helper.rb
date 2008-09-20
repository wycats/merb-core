module Merb
  module Test
    module RouteHelper
      include RequestHelper
      
      # Mimics the url method available to controllers.
      #
      # ==== Parameters
      # name<~to_sym>:: The name of the URL to generate.
      # params<Hash>:: Parameters for the route generation.
      #
      # ==== Returns
      # String:: The generated URL.
      def url(*args)
        name = args.first.is_a?(Symbol) ? args.shift : :default
        
        unless route = Merb::Router.named_routes[name]
          raise Merb::Router::GenerationError, "Named route not found: #{name}"
        end

        route.generate(args, @request_params || {})
      end
      
      # ==== Parameters
      # path<~to_string>:: The URL of the request.
      # method<~to_sym>:: HTTP request method.
      # env<Hash>:: Additional parameters for the request.
      #
      # ==== Returns
      # Hash:: A hash containing the controller and action along with any parameters
      def request_to(path, method = :get, env = {})
        env[:request_method] ||= method.to_s.upcase
        env[:request_uri] = path
        
        check_request_for_route(build_request({}, env))
      end
    end
  end
end