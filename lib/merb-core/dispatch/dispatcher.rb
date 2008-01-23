class Merb::Dispatcher
  DEFAULT_ERROR_TEMPLATE = File.expand_path(File.dirname(__FILE__) / 'exceptions.html.erb')
  
  class << self
    
    attr_accessor :use_mutex
    
    @@mutex = Mutex.new
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
    #   An array containing the Merb::Controller and the action that was dispatched to.
    def handle(rack_env, response)
      start   = Time.now
      request = Merb::Request.new(rack_env)
      Merb.logger.info("Params: #{request.params.inspect}")
      Merb.logger.info("Cookies: #{request.cookies.inspect}")
      
      # user friendly error messages
      if request.route_params.empty?
        raise ::Merb::ControllerExceptions::BadRequest, "No routes match the request"
      elsif request.controller_name.nil?
        raise ::Merb::ControllerExceptions::BadRequest, "Route matched, but route did not specify a controller" 
      end
      
      Merb.logger.debug("Routed to: #{request.route_params.inspect}")

      # set controller class and the action to call
      klass = request.controller_class
      controller, action = dispatch_action(klass, request.action, request, response)
      Merb.logger.info controller._benchmarks.inspect
      Merb.logger.flush

      [controller, action]
    # this is the custom dispatch_exception; it allows failures to still be dispatched
    # to the error controller
    rescue => exception
      Merb.logger.error(Merb.exception(exception))
      exception = controller_exception(exception)
      dispatch_exception(request, response, exception)
    end
    
    private
    # Setup the controller and call the chosen action 
    #
    # ==== Parameters
    # klass<Merb::Controller>:: the class to dispatch to
    # action<Symbol>::          the action to dispatch
    # request<Merb::Request>::  the Merb::Request object that was created in #handle
    # response<IO>::            the response object passed in from Mongrel
    # status<Integer>::         the status code to respond with
    #
    # ==== Returns
    # Array[Merb::Controller, Symbol]::
    #   An array containing the Merb::Controller and the action that was dispatched to.
    def dispatch_action(klass, action, request, response, status=200)
      # build controller
      controller = klass.new(request, response, status)
      if use_mutex
        @@mutex.synchronize { controller._dispatch(action) }
      else
        controller._dispatch(action)
      end
      [controller, action]
    end
    
    # Re-route the current request to the Exception controller
    # if it is available, and try to render the exception nicely.
    #
    # If it is not available then just render a simple text error.
    #
    # ==== Parameters
    # request<Merb::Request>:: 
    #   The request object associated with the failed request
    # response<IO>::
    #   The response object to put the response into
    # exception<Object>::
    #   The exception object that was created when trying to dispatch the
    #   original controller.
    #
    # ==== Returns
    # Array[Merb::Controller, String]::
    #   An array containing the Merb::Controller and the name of the exception
    #   that triggrered #dispatch_exception. For instance, a NotFound exception
    #   will be "not_found".
    def dispatch_exception(request, response, exception)
      klass = ::Exceptions rescue Merb::Controller
      request.params[:original_params] = request.params.dup rescue {}
      request.params[:original_session] = request.session.dup rescue {}
      request.params[:original_cookies] = request.cookies.dup rescue {}
      request.params[:exception] = exception
      request.params[:action] = exception.name
      dispatch_action(klass, exception.name, request, response, exception.class::STATUS)
    rescue => dispatch_issue
      dispatch_issue = controller_exception(dispatch_issue)  
      # when no action/template exist for an exception, or an
      # exception occurs on an InternalServerError the message is
      # rendered as simple text.
      # ControllerExceptions raised from exception actions are 
      # dispatched back into the Exceptions controller
      if dispatch_issue.is_a?(Merb::ControllerExceptions::NotFound)
        dispatch_default_exception(klass, request, response, exception)
      elsif dispatch_issue.is_a?(Merb::ControllerExceptions::InternalServerError)
        dispatch_default_exception(klass, request, response, dispatch_issue)
      else
        exception = dispatch_issue
        retry
      end
    end
    
    # If no custom actions are available to render an exception
    # then the errors will end up here for processing
    #
    # ==== Parameters
    # klass<Merb::Controller>:: 
    #   The class of the controller to use for exception dispatch
    # request<Merb::Request>::
    #   The Merb request that produced the original error
    # response<IO>::
    #   The response object that the response will be put into
    # e<Exception>::
    #   The exception that caused #dispatch_exception to be called
    #
    # ==== Returns
    # Array[Merb::Controller, String]::
    #   An array containing the Merb::Controller that was dispatched to
    #   and the error's name. For instance, a NotFound error's name is
    #   "not_found".
    def dispatch_default_exception(klass, request, response, e)
      controller = klass.new(request, response, e.class::STATUS)
      if e.is_a? Merb::ControllerExceptions::Redirection
        controller.headers.merge!('Location' => e.message)
        controller.body = %{ } #fix
      else
        controller.instance_variable_set("@exception", e) # for ERB
        controller.instance_variable_set("@exception_name", e.name.split("_").map {|x| x.capitalize}.join(" "))
        controller.body = controller.send(Merb::Template.template_for(DEFAULT_ERROR_TEMPLATE))
      end
      [controller, e.name]
    end
    
    # Wraps any non-ControllerException errors in an 
    # InternalServerError ready for displaying over HTTP
    #
    # ==== Parameters
    # e<Exception>::
    #   The exception that caused #dispatch_exception to be called
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