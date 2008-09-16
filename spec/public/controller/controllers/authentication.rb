module Merb::Test::Fixtures::Controllers

  class Testing < Merb::Controller
    self._template_root = File.dirname(__FILE__) / "views"
  end

  class BasicAuthentication < Testing
    before :authenticate, :only => :index

    def index
      "authenticated"
    end

    protected

    def authenticate
      basic_authentication { |u, p| u == "Fred" && p == "secret" }
    end
  end

  class BasicAuthenticationWithRealm < BasicAuthentication
    def authenticate
      basic_authentication("My Super App") { |u, p| u == "Fred" && p == "secret" }
    end
  end

  class AuthenticateBasicAuthentication < Testing
    def index
      basic_authentication.authenticate { |u, p| "Fred:secret" }
    end
  end

  class RequestBasicAuthentication < BasicAuthentication
    def authenticate
      basic_authentication.request
    end
  end

  class RequestBasicAuthenticationWithRealm < BasicAuthentication
    def authenticate
      basic_authentication("My SuperApp").request
    end
  end
  
  class PassiveBasicAuthentication < BasicAuthentication
        
    def index
      "My Output"
    end
    
    def authenticate
      basic_authentication.request!
    end
  end
  
  class PassiveBasicAuthenticationWithRealm < BasicAuthentication
    def authenticate
      basic_authentication("My Super App").request!
    end
  end
  
  class PassiveBasicAuthenticationInAction < BasicAuthentication
    
    def index
      basic_authentication.request!
      "In Action"
    end
    
    def authenticate
      true
    end
  end

end
