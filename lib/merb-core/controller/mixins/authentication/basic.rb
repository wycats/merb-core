module Merb::BasicAuthenticationMixin
  # So we can have access to the status codes
  include Merb::ControllerExceptions
  
  def authenticate_or_request_with_http_basic(realm = "Application", &authenticator)
    authenticate_with_http_basic(&authenticator) || request_http_basic_authentication(realm)
  end

  def authenticate_with_http_basic(&authenticator)
    app = Proc.new { |env| OK::STATUS }
    auth = Rack::Auth::Basic.new(app, &authenticator)
    auth.call(request.env) == OK::STATUS
  end

  def request_http_basic_authentication(realm = "Application")
    headers['WWW-Authenticate'] = 'Basic realm="%s"' % realm
    throw :halt, render("HTTP Basic: Access denied.\n", :status => Unauthorized::STATUS, :layout => false)
  end
end