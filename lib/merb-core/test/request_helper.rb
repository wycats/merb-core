

module Merb::Test::RequestHelper

  # ==== Parameters
  # env<Hash>:: A hash of environment keys to be merged into the default list
  # opt<Hash>:: A hash of options (see below)
  #
  # ==== Options (choose one)
  # :post_body<String>:: The post body for the request
  # :body<String>:: The body for the request
  # 
  # ==== Returns
  # FakeRequest:: A Request object that is built based on the parameters
  #
  # ==== Note
  # If you pass a post_body, the content-type will be set as URL-encoded
  #
  #---
  # @public

  def fake_request(env = {}, opt = {})
    if opt[:post_body]
      req = opt[:post_body]
      env.merge!(:content_type => "application/x-www-form-urlencoded")
    else
      req = opt[:req]
    end
    Merb::Test::FakeRequest.new(env, req ? StringIO.new(req) : nil)
  end

  def dispatch_to(controller_klass, action, params = {}, env = {}, &blk)
    request = fake_request(env, 
      :query_string => Merb::Responder.params_to_query_string(params))

    controller = controller_klass.new(request)
    controller.instance_eval(&blk) if block_given?
    controller._dispatch(action)
    
    Merb.logger.info controller._benchmarks.inspect
    Merb.logger.flush    
    
    controller
  end
end