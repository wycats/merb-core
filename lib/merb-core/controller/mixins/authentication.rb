module Merb::AuthenticationMixin
  
  def basic_authentication(realm = "Application", &authenticator)
    BasicAuthentication.new(self, realm, &authenticator)
  end
  
  class BasicAuthentication
    # So we can have access to the status codes
    include Merb::ControllerExceptions

    def initialize(controller, realm = "Application", &authenticator)
      @controller = controller
      @realm = realm
      authenticate_or_request(&authenticator) if authenticator
    end

    def authenticate(&authenticator)
      auth = Rack::Auth::Basic::Request.new(@controller.request.env)

      if auth.provided? and auth.basic?
        authenticator.call(*auth.credentials)
      else
        false
      end
    end

    def request
      @controller.headers['WWW-Authenticate'] = 'Basic realm="%s"' % @realm
      throw :halt, @controller.render("HTTP Basic: Access denied.\n", :status => Unauthorized::STATUS, :layout => false)
    end
    
    protected
    
    def authenticate_or_request(&authenticator)
      authenticate(&authenticator) || request
    end
    
  end

end
