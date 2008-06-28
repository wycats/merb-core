class Merb::Dispatcher
  DEFAULT_ERROR_TEMPLATE = File.expand_path(File.dirname(__FILE__) / 'exceptions.html')
  
  class << self
    
    attr_accessor :use_mutex
    
    @@mutex = Mutex.new
    @@work_queue = Queue.new
    
    def work_queue 
      @@work_queue
    end  
    
    Merb::Dispatcher.use_mutex = ::Merb::Config[:use_mutex]
    
    # This is where we grab the incoming request REQUEST_URI and use that in
    # the merb RouteMatcher to determine which controller and method to run.
    # Returns a 2 element tuple of: [controller, action]
    #
    # ControllerExceptions are rescued here and redispatched.
    #
    # ==== Parameters
    # rack_env<Rack::Environment>::
    #   The rack environment, which is used to instantiate a Merb::Request
    # response<IO>::
    #   An IO object to hold the response
    #
    # ==== Returns
    # Array[Merb::Controller, Symbol]::
    #   An array containing the Merb::Controller and the action that was
    #   dispatched to.
    def handle(rack_env)
      start   = Time.now
      request = Merb::Request.new(rack_env)
      Merb.logger.info "Started request handling: #{start.to_s}"
      
      route_index, route_params = Merb::Router.match(request)
      route = Merb::Router.routes[route_index] if route_index
 
      return dispatch_redirection(request,route) if route && route.behavior.redirects?      
      
      if route_params.empty?
        raise ::Merb::ControllerExceptions::NotFound, "No routes match the request: #{request.uri}."
      end
      request.route_params = route_params
      request.params.merge! route_params
            
      controller_name = (route_params[:namespace] ? route_params[:namespace] + '/' : '') + route_params[:controller]
      
      unless controller_name
        raise Merb::ControllerExceptions::NotFound, "Route matched, but route did not specify a controller. Did you forgot to add :controller => \"people\" or :controller segment to route definition? Here is what's specified: #{request.route_params.inspect}" 
      end
      
      Merb.logger.debug("Routed to: #{request.route_params.inspect}")

      cnt = controller_name.snake_case.to_const_string
      
      if !Merb::Controller._subclasses.include?(cnt)
        raise Merb::ControllerExceptions::NotFound, "Controller '#{cnt}' not found. If Merb tries to look for a controller for static files, you way need to check up your Rackup file, see Problems section at: http://wiki.merbivore.com/pages/rack-middleware"
      end
      if cnt == "Application"
        raise Merb::ControllerExceptions::NotFound, "The 'Application' controller has no public actions"
      end

      begin
        klass = Object.full_const_get(cnt)
      rescue NameError => e
        Merb.logger.warn!("Controller class not found for controller #{controller_name}: #{e.message}")
        raise Merb::ControllerExceptions::NotFound
      end

      Merb.logger.info("Params: #{klass._filter_params(request.params).inspect}")

      action = route_params[:action]

      if route.allow_fixation? && request.params.key?(Merb::Controller._session_id_key)
        Merb.logger.info("Fixated session id: #{Merb::Controller._session_id_key}")
        request.cookies[Merb::Controller._session_id_key] = request.params[Merb::Controller._session_id_key]
      end  
      
      controller = dispatch_action(klass, action, request)
      controller._benchmarks[:dispatch_time] = Time.now - start
      controller.route = route
      Merb.logger.info controller._benchmarks.inspect
      Merb.logger.flush

      controller
    # this is the custom dispatch_exception; it allows failures to still be dispatched
    # to the error controller
    rescue => exception
      Merb.logger.error(Merb.exception(exception))
      unless request.xhr?
        exception = controller_exception(exception)
        dispatch_exception(request, exception)
      else
        Struct.new(:headers, :status, :body).new({}, 500,
          <<-HERE
#{exception.message}
 
Params:
#{(request.params || {}).map { |p,v| "  #{p}: #{v}\n"}.join("\n")}
 
Session:
#{(request.session || {}).map { |p,v| "  #{p}: #{v}\n"}.join("\n")}
 
Cookies:
#{(request.cookies || {}).map { |p,v| "  #{p}: #{v}\n"}.join("\n")}
 
Stacktrace:
#{exception.backtrace.join("\n")}
          HERE
        )
      end
    end
    
    private
    # Setup the controller and call the chosen action 
    #
    # ==== Parameters
    # klass<Merb::Controller>:: The controller class to dispatch to.
    # action<Symbol>:: The action to dispatch.
    # request<Merb::Request>::
    #   The Merb::Request object that was created in #handle
    # response<IO>:: The response object passed in from Mongrel
    # status<Integer>:: The status code to respond with.
    #
    # ==== Returns
    # Array[Merb::Controller, Symbol]::
    #   An array containing the Merb::Controller and the action that was
    #   dispatched to.
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
    # such as client_error
    #
    # If it is not available then just render a simple text error.
    #
    # ==== Parameters
    # request<Merb::Request>:: 
    #   The request object associated with the failed request.
    # response<IO>::
    #   The response object to put the response into.
    # exception<Object>::
    #   The exception object that was created when trying to dispatch the
    #   original controller.
    #
    # ==== Returns
    # Array[Merb::Controller, String]::
    #   An array containing the Merb::Controller and the name of the exception
    #   that triggrered #dispatch_exception. For instance, a NotFound exception
    #   will be "not_found".
    def dispatch_exception(request, exception)
      exception_klass = exception.class
      begin
        klass = ::Exceptions rescue Merb::Controller
        request.params[:original_params] = request.params.dup rescue {}
        request.params[:original_session] = request.session.dup rescue {}
        request.params[:original_cookies] = request.cookies.dup rescue {}
        request.params[:exception] = exception
        request.params[:action] = exception_klass.name
        
        dispatch_action(klass, exception_klass.name, request, exception.class.status)
      rescue => dispatch_issue       
        dispatch_issue = controller_exception(dispatch_issue)  
        # when no action/template exist for an exception, or an
        # exception occurs on an InternalServerError the message is
        # rendered as simple text.
        
        # ControllerExceptions raised from exception actions are 
        # dispatched back into the Exceptions controller
        if dispatch_issue.is_a?(Merb::ControllerExceptions::NotFound)
          # If a handler for a specific exception is not found, keep retrying 
          # with the more general cases until we reach the base exception.
          unless exception_klass == Merb::ControllerExceptions::Base
            exception_klass = exception_klass.superclass
            retry
          else
            dispatch_default_exception(klass, request, exception)
          end       
        elsif request.params[:exception].is_a?(dispatch_issue.class)
          dispatch_default_exception(klass, request, dispatch_issue)
        elsif dispatch_issue.is_a?(Merb::ControllerExceptions::InternalServerError)
          dispatch_default_exception(klass, request, dispatch_issue)
        else
          exception = dispatch_issue
          retry
        end
      end
    end
    
    # If no custom actions are available to render an exception then the errors
    # will end up here for processing
    #
    # ==== Parameters
    # klass<Merb::Controller>:: 
    #   The class of the controller to use for exception dispatch.
    # request<Merb::Request>::
    #   The Merb request that produced the original error.
    # response<IO>::
    #   The response object that the response will be put into.
    # e<Exception>::
    #   The exception that caused #dispatch_exception to be called.
    #
    # ==== Returns
    # Array[Merb::Controller, String]::
    #   An array containing the Merb::Controller that was dispatched to and the
    #   error's name. For instance, a NotFound error's name is "not_found".
    def dispatch_default_exception(klass, request, e)
      controller = klass.new(request, e.class.status)
      if e.is_a? Merb::ControllerExceptions::Redirection
        controller.headers.merge!('Location' => e.message)
        controller.body = %{ } #fix
      else
        controller.instance_variable_set("@exception", e) # for ERB
        controller.instance_variable_set("@exception_name", e.name.split("_").map {|x| x.capitalize}.join(" "))
        controller.body = controller.send(Merb::Template.template_for(DEFAULT_ERROR_TEMPLATE))
      end
      controller
    end

    # Set up a faux controller to do redirection from the router 
    #
    # ==== Parameters
    # request<Merb::Request>::
    #   The Merb::Request object that was created in #handle
    # route<Merb::Router::Route>:: Matched route object
    #
    # ==== Example
    # r.match("/my/old/crusty/url").redirect("http://example.com/index.html")
    #
    # ==== Returns
    # Merb::Controller::
    #   Merb::Controller set with redirect headers and a 301/302 status
    def dispatch_redirection(request, route)
      status  = route.behavior.redirect_status
      url     = route.behavior.redirect_url

      controller = Merb::Controller.new(request,status)
      
      Merb.logger.info("Dispatcher redirecting to: #{url} (#{status})")
      
      controller.headers['Location'] = url
      controller.body = "<html><body>You are being <a href=\"#{url}\">redirected</a>.</body></html>"
      controller
    end
    
    
    # Wraps any non-ControllerException errors in an InternalServerError ready
    # for displaying over HTTP.
    #
    # ==== Parameters
    # e<Exception>::
    #   The exception that caused #dispatch_exception to be called.
    #
    # ==== Returns
    # Merb::InternalServerError::
    #   An internal server error wrapper for the exception.
    def controller_exception(e)
      e.kind_of?(Merb::ControllerExceptions::Base) ?
        e : Merb::ControllerExceptions::InternalServerError.new(e) 
    end    
    
  end
end
