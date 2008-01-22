class Merb::Dispatcher
  class << self
    
    attr_accessor :use_mutex
    
    @@mutex = Mutex.new
    Merb::Dispatcher.use_mutex = ::Merb::Config[:use_mutex]
    
    # This is where we grab the incoming request REQUEST_URI and use that in
    # the merb RouteMatcher to determine which controller and method to run.
    # Returns a 2 element tuple of: [controller, action]
    #
    # ControllerExceptions are rescued here and redispatched.
    # Exceptions still return [controller, action]
    def handle(http_request, response)
      start   = Time.now
      request = Merb::Request.new(http_request)
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
    # rescue => exception
    #   Merb.logger.error(Merb.exception(exception))
    #   exception = controller_exception(exception)
    #   dispatch_exception(request, response, exception)
    end
    
    private
    # setup the controller and call the chosen action 
    #   klass<Merb::Controller> the class to dispatch to
    #   action<Symbol>          the action to dispatch
    #   request<Merb::Request>  the Merb::Request object that was created in #handle
    #   response<HTTPResponse>  the response object passed in from Mongrel
    #   status<Integer>         the status code to respond with
    def dispatch_action(klass, action, request, response, status=200)
      # build controller
      controller = klass.build(request, response, status)
      if use_mutex
        @@mutex.synchronize { controller._dispatch(action) }
      else
        controller._dispatch(action)
      end
      [controller, action]
    end
    
  end
end