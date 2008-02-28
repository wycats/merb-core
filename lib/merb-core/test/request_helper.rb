require 'tempfile'

module Merb::Test::RequestHelper

  # ==== Parameters
  # env<Hash>:: A hash of environment keys to be merged into the default list.
  # opt<Hash>:: A hash of options (see below).
  #
  # ==== Options (opt)
  # :post_body<String>:: The post body for the request.
  # :req<String>::
  #   The request string. This will only be used if :post_body is left out.
  # 
  # ==== Returns
  # FakeRequest:: A Request object that is built based on the parameters.
  #
  # ==== Note
  # If you pass a post body, the content-type will be set to URL-encoded.
  #
  #---
  # @public
  def fake_request(env = {}, opt = {})
    if opt[:post_body]
      req = opt[:post_body]
      env[:content_type] ||= "application/x-www-form-urlencoded"
    else
      req = opt[:req]
    end
    Merb::Test::FakeRequest.new(env, req ? StringIO.new(req) : nil) 
  end

  # Dispatches an action to the given class. This bypasses the router and is
  # suitable for unit testing of controllers.
  #
  # ==== Parameters
  # controller_klass<Controller>::
  #   The controller class object that the action should be dispatched to.
  # action<Symbol>:: The action name, as a symbol.
  # params<Hash>::
  #   An optional hash that will end up as params in the controller instance.
  # env<Hash>::
  #   An optional hash that is passed to the fake request. Any request options
  #   should go here (see +fake_request+).
  # &blk::
  #   The controller is yielded to the block provided for actions *prior* to
  #   the action being dispatched.
  #
  # ==== Example
  #   dispatch_to(MyController, :create, :name => 'Homer' ) do
  #     self.stub!(:current_user).and_return(@user)
  #   end
  #
  # ==== Note
  # Does not use routes.
  #
  #---
  # @public
  def dispatch_to(controller_klass, action, params = {}, env = {}, &blk)
    request = fake_request(env.merge(
      :query_string => Merb::Request.params_to_query_string(params)))

    dispatch_request(request, controller_klass, action, &blk)
  end
  
  
  # Similar to dispatch_to but allows for sending files inside params.  
  #
  # ==== Paramters 
  # controller_klass<Controller>::
  #   The controller class object that the action should be dispatched to.
  # action<Symbol>:: The action name, as a symbol.
  # params<Hash>::
  #   An optional hash that will end up as params in the controller instance.
  # env<Hash>::
  #   An optional hash that is passed to the fake request. Any request options
  #   should go here (see +fake_request+).
  # &blk:: The block is executed in the context of the controller.
  #  
  # ==== Example
  #   dispatch_multipart_to(MyController, :create, :my_file => @a_file ) do
  #     self.stub!(:current_user).and_return(@user)
  #   end
  #
  # ==== Note
  # Set your option to contain a file object to simulate file uploads.
  #   
  # Does not use routes.
  #---
  # @public
  def dispatch_multipart_to(controller_klass, action, params = {}, env = {}, &blk)
    request = multipart_fake_request(env, params)
    dispatch_request(request, controller_klass, action, &blk)
  end
  
  # An HTTP GET request that operates through the router.
  #
  # ==== Parameters
  # path<String>:: The path that should go to the router as the request uri.
  # params<Hash>::
  #   An optional hash that will end up as params in the controller instance.
  # env<Hash>::
  #   An optional hash that is passed to the fake request. Any request options
  #   should go here (see +fake_request+).
  # &block:: The block is executed in the context of the controller.
  def get(path, params = {}, env = {}, &block)
    env[:request_method] = "GET"
    request(path, params, env, &block)
  end
  
  # An HTTP POST request that operates through the router.
  #
  # ==== Parameters
  # path<String>:: The path that should go to the router as the request uri.
  # params<Hash>::
  #   An optional hash that will end up as params in the controller instance.
  # env<Hash>::
  #   An optional hash that is passed to the fake request. Any request options
  #   should go here (see fake_request).
  # &block:: The block is executed in the context of the controller.
  def post(path, params = {}, env = {}, &block)
    env[:request_method] = "POST"
    request(path, params, env, &block)
  end
  
  # An HTTP PUT request that operates through the router.
  #
  # ==== Parameters
  # path<String>:: The path that should go to the router as the request uri.
  # params<Hash>::
  #   An optional hash that will end up as params in the controller instance.
  # env<Hash>::
  #   An optional hash that is passed to the fake request. Any request options
  #   should go here (see fake_request).
  # &block:: The block is executed in the context of the controller.
  def put(path, params = {}, env = {}, &block)
    env[:request_method] = "PUT"
    request(path, params, env, &block)
  end
  
  # An HTTP DELETE request that operates through the router
  #
  # ==== Parameters
  # path<String>:: The path that should go to the router as the request uri.
  # params<Hash>::
  #   An optional hash that will end up as params in the controller instance.
  # env<Hash>::
  #   An optional hash that is passed to the fake request. Any request options
  #   should go here (see fake_request).
  # &block:: The block is executed in the context of the controller.
  def delete(path, params = {}, env = {}, &block)
    env[:request_method] = "DELETE"
    request(path, params, env, &block)
  end
  
  
  # An HTTP POST request that operates through the router and uses multipart
  # parameters.
  #
  # ==== Parameters
  # path<String>:: The path that should go to the router as the request uri.
  # params<Hash>::
  #   An optional hash that will end up as params in the controller instance.
  # env<Hash>::
  #   An optional hash that is passed to the fake request. Any request options
  #   should go here (see +fake_request+).
  # &block:: The block is executed in the context of the controller.
  #
  # ==== Note
  # To include an uploaded file, put a file object as a value in params.
  def multipart_post(path, params = {}, env = {}, &block)
    env[:request_method] = "POST"
    env[:test_with_multipart] = true
    request(path, params, env, &block)
  end
  
  # An HTTP PUT request that operates through the router and uses multipart
  # parameters.
  #
  # ==== Parameters
  # path<String>:: The path that should go to the router as the request uri.
  # params<Hash>::
  #   An optional hash that will end up as params in the controller instance.
  # env<Hash>::
  #   An optional hash that is passed to the fake request. Any request options
  #   should go here (see +fake_request+).
  # &block:: The block is executed in the context of the controller.
  #
  # ==== Note
  # To include an uplaoded file, put a file object as a value in params.
  def multipart_put(path, params = {}, env = {}, &block)
    env[:request_method] = "PUT"
    env[:test_with_multipart] = true
    request(path, params, env, &block)
  end
  
  

  # A generic request that checks the router for the controller and action.
  # This request goes through the Merb::Router and finishes at the controller.
  #
  # ==== Parameters
  # path<String>:: The path that should go to the router as the request uri.
  # params<Hash>::
  #   An optional hash that will end up as params in the controller instance.
  # env<Hash>::
  #   An optional hash that is passed to the fake request. Any request options
  #   should go here (see +fake_request+).
  # &block:: The block is executed in the context of the controller.
  #
  # ==== Example
  #   request(path, :create, :name => 'Homer' ) do
  #     self.stub!(:current_user).and_return(@user)
  #   end
  #
  # ==== Note
  # Uses Routes.
  #
  #---
  # @semi-public  
  def request(path, params = {}, env= {}, &block)
    env[:request_method] ||= "GET"
    env[:request_uri] = path
    multipart = env.delete(:test_with_multipart)
    
    request = fake_request(env)
    
    opts = check_request_for_route(request) # Check that the request will be routed correctly
    klass = Object.full_const_get(opts.delete(:controller).to_const_string)
    action = opts.delete(:action).to_s
    params.merge!(opts)
  
    multipart.nil? ? dispatch_to(klass, action, params, env, &block) : dispatch_multipart_to(klass, action, params, env, &block)
  end


  # The workhorse for the dispatch*to helpers.
  # 
  # ==== Parameters
  # request<Merb::Test::FakeRequest, Merb::Request>::
  #   A request object that has been setup for testing.
  # controller_klass<Merb::Controller>::
  #   The class object off the controller to dispatch the action to.
  # action<Symbol>:: The action to dispatch the request to.
  # &blk:: The block will execute in the context of the controller itself.
  #
  # ==== Block parameters (&blk)
  # controller<Merb::Controller>:: The controller that's handling the dispatch.
  #
  # ==== Returns
  # An instance of +controller_klass+ based on the parameters.
  #
  # ==== Note
  # Does not use routes.
  #
  #---
  # @private
  def dispatch_request(request, controller_klass, action, &blk)
    controller = controller_klass.new(request)
    yield controller if block_given?
    controller._dispatch(action)

    Merb.logger.info controller._benchmarks.inspect
    Merb.logger.flush

    controller
  end

  # ==== Parameters
  # env<Hash>::
  #   An optional hash that is passed to the fake request. Any request options
  #   should go here (see +fake_request+).
  # params<Hash>::
  #   An optional hash that will end up as params in the controller instance.
  # 
  # ==== Returns
  # FakeRequest::
  #   A multipart Request object that is built based on the parameters.
  def multipart_fake_request(env = {}, params = {})
    if params.empty?
      fake_request(env)
    else
      m = Merb::Test::Multipart::Post.new(params)
      body, head = m.to_multipart
      fake_request(env.merge( :content_type => head, 
                              :content_length => body.length), :post_body => body)
    end
  end
  
  # Checks to see that a request is routable.
  # 
  # ==== Parameters
  # request<Merb::Test::FakeRequest, Merb::Request>::
  #   The request object to inspect.
  #
  # ==== Raises
  # Merb::ControllerExceptions::BadRequest::
  #   No matching route was found.
  #
  # ==== Returns
  # Hash:: The parameters built based on the matching route.
  def check_request_for_route(request)
    match =  ::Merb::Router.match(request)
    if match[0].nil?
      raise ::Merb::ControllerExceptions::BadRequest, "No routes match the request"
    else
      match[1]
    end
  end
end