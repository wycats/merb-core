require Merb.framework_root / "merb-core" / "dispatch" / "default_exception" / "default_exception"
module Merb
  class Dispatcher
    class << self
      include Merb::ControllerExceptions
    
      attr_accessor :use_mutex
    
      @@mutex = Mutex.new
      @@work_queue = Queue.new
    
      def work_queue 
        @@work_queue
      end  
    
      Merb::Dispatcher.use_mutex = ::Merb::Config[:use_mutex]
    
      # Dispatch the rack environment. ControllerExceptions are rescued here
      # and redispatched.
      #
      # ==== Parameters
      # rack_env<Rack::Environment>::
      #   The rack environment, which is used to instantiate a Merb::Request
      #
      # ==== Returns
      # Merb::Controller::
      #   The Merb::Controller that was dispatched to
      def handle(request)
        start = Time.now
        Merb.logger.info "Started request handling: #{start.to_s}"
    
        request.find_route
        return redirect(request) if request.redirects?
        
        klass = request.controller
        Merb.logger.debug("Routed to: #{request.params.inspect}")
        
        unless klass < Controller
          raise NotFound, 
            "Controller '#{klass}' not found.\n" <<
            "If Merb tries to look for a controller for static files, " <<
            "you way need to check up your Rackup file, see the Problems " <<
            "section at: http://wiki.merbivore.com/pages/rack-middleware"
        end
      
        if klass.name == "Application"
          raise NotFound, "The 'Application' controller has no public actions"
        end
      
        # TODO: move fixation logic to session loading
        controller = dispatch_action(klass, request.params[:action], request)
        controller._benchmarks[:dispatch_time] = Time.now - start
        Merb.logger.info controller._benchmarks.inspect
        Merb.logger.flush
        controller
      rescue Object => exception
        dispatch_exception(exception, request)
      end
        
  #     def handle(rack_env)
  #       start   = Time.now
  #       request = Merb::Request.new(rack_env)
  #       Merb.logger.info "Started request handling: #{start.to_s}"
  #       
  #       route_index, route_params = Merb::Router.match(request)
  #       route = Merb::Router.routes[route_index] if route_index
  #  
  #       return dispatch_redirection(request,route) if route && route.behavior.redirects?      
  #       
  #       if route_params.empty?
  #         raise ::Merb::ControllerExceptions::NotFound, "No routes match the request: #{request.uri}."
  #       end
  #       request.route_params = route_params
  #       request.params.merge! route_params
  #             
  #       controller_name = (route_params[:namespace] ? route_params[:namespace] + '/' : '') + route_params[:controller]
  #       
  #       unless controller_name
  #         raise Merb::ControllerExceptions::NotFound, "Route matched, but route did not specify a controller. Did you forgot to add :controller => \"people\" or :controller segment to route definition? Here is what's specified: #{request.route_params.inspect}" 
  #       end
  #       
  #       Merb.logger.debug("Routed to: #{request.route_params.inspect}")
  # 
  #       cnt = controller_name.snake_case.to_const_string
  #       
  #       if !Merb::Controller._subclasses.include?(cnt)
  #         raise Merb::ControllerExceptions::NotFound, "Controller '#{cnt}' not found. If Merb tries to look for a controller for static files, you way need to check up your Rackup file, see Problems section at: http://wiki.merbivore.com/pages/rack-middleware"
  #       end
  #       if cnt == "Application"
  #         raise Merb::ControllerExceptions::NotFound, "The 'Application' controller has no public actions"
  #       end
  # 
  #       begin
  #         klass = Object.full_const_get(cnt)
  #       rescue NameError => e
  #         Merb.logger.warn!("Controller class not found for controller #{controller_name}: #{e.message}")
  #         raise Merb::ControllerExceptions::NotFound
  #       end
  # 
  #       Merb.logger.info("Params: #{klass._filter_params(request.params).inspect}")
  # 
  #       action = route_params[:action]
  # 
  #       if route.allow_fixation? && request.params.key?(Merb::Controller._session_id_key)
  #         Merb.logger.info("Fixated session id: #{Merb::Controller._session_id_key}")
  #         request.cookies[Merb::Controller._session_id_key] = request.params[Merb::Controller._session_id_key]
  #       end
  #       
  #       controller = dispatch_action(klass, action, request)
  #       controller._benchmarks[:dispatch_time] = Time.now - start
  #       controller.route = route
  #       Merb.logger.info controller._benchmarks.inspect
  #       Merb.logger.flush
  # 
  #       controller
  #     # this is the custom dispatch_exception; it allows failures to still be dispatched
  #     # to the error controller
  #     rescue => exception
  #       Merb.logger.error(Merb.exception(exception))
  #       unless request.xhr?
  #         exception = controller_exception(exception)
  #         dispatch_exception(request, exception)
  #       else
  #         Struct.new(:headers, :status, :body).new({}, 500,
  #           <<-HERE
  # #{exception.message}
  #  
  # Params:
  # #{(request.params || {}).map { |p,v| "  #{p}: #{v}\n"}.join("\n")}
  #  
  # Session:
  # #{(request.session || {}).map { |p,v| "  #{p}: #{v}\n"}.join("\n")}
  #  
  # Cookies:
  # #{(request.cookies || {}).map { |p,v| "  #{p}: #{v}\n"}.join("\n")}
  #  
  # Stacktrace:
  # #{exception.backtrace.join("\n")}
  #           HERE
  #         )
  #       end
  #     end
    
      private
      # Setup the controller and call the chosen action 
      #
      # ==== Parameters
      # klass<Merb::Controller>:: The controller class to dispatch to.
      # action<Symbol>:: The action to dispatch.
      # request<Merb::Request>::
      #   The Merb::Request object that was created in #handle
      # status<Integer>:: The status code to respond with.
      #
      # ==== Returns
      # Merb::Controller::
      #   The Merb::Controller that was dispatched to.
      def dispatch_action(klass, action, request, status=200)
        # build controller
        controller = klass.new(request, status)
        if use_mutex
          @@mutex.synchronize { controller._dispatch(action) }
        else
          controller._dispatch(action)
        end
        controller
      end
    
      # Re-route the current request to the Exception controller if it is
      # available, and try to render the exception nicely.  
      #
      # You can handle exceptions by implementing actions for specific
      # exceptions such as not_found or for entire classes of exceptions
      # such as client_error. You can also implement handlers for 
      # exceptions outside the Merb exception hierarchy (e.g.
      # StandardError is caught in standard_error).
      #
      # ==== Parameters
      # request<Merb::Request>:: 
      #   The request object associated with the failed request.
      # exception<Object>::
      #   The exception object that was created when trying to dispatch the
      #   original controller.
      #
      # ==== Returns
      # Exceptions::
      #   The Merb::Controller that was dispatched to. 
      def dispatch_exception(exception, request)
        Merb.logger.error(Merb.exception(exception))
        request.exceptions = [exception]
        
        begin
          e = request.exceptions.first
          
          if action_name = e.action_name
            dispatch_action(Exceptions, action_name, request, e.class.status)
          else
            dispatch_default_exception(request, e.class.status)
          end          
        rescue Object => dispatch_issue
          if e.same?(dispatch_issue)
            dispatch_default_exception(request, e.class.status)
          else
            Merb.logger.error("Dispatching #{e.class} raised another error.")
            Merb.logger.error(Merb.exception(dispatch_issue))
            
            request.exceptions.unshift dispatch_issue
            retry
          end
        end
      end
    
      # If no custom actions are available to render an exception then the errors
      # will end up here for processing
      #
      # ==== Parameters
      # request<Merb::Request>::
      #   The Merb request that produced the original error.
      # status<Integer>::
      #   The status code to return with the Exception.
      #
      # ==== Returns
      # Merb::Dispatcher::DefaultException::
      #   The DefaultException that was dispatched to.
      def dispatch_default_exception(request, status)
        Merb::Dispatcher::DefaultException.new(request, status)._dispatch
      end

      # Set up a faux controller to do redirection from the router 
      #
      # ==== Parameters
      # request<Merb::Request>::
      #   The Merb::Request object that was created in #handle
      # status<Integer>::
      #   The status code to return with the controller
      # url<String>::
      #   The URL to return
      #
      # ==== Example
      # r.match("/my/old/crusty/url").redirect("http://example.com/index.html")
      #
      # ==== Returns
      # Merb::Controller::
      #   Merb::Controller set with redirect headers and a 301/302 status
      def redirect(request)
        status, url = request.redirect_status, request.redirect_url
        controller = Merb::Controller.new(request, status)
      
        Merb.logger.info("Dispatcher redirecting to: #{url} (#{status})")
        Merb.logger.flush
        
        controller.headers['Location'] = url
        controller.body = "<html><body>You are being <a href=\"#{url}\">redirected</a>.</body></html>"
        controller
      end
    
    end
  end
end