module Merb::Test::Fixtures::Controllers

  class Testing < Merb::Controller
    self._template_root = File.dirname(__FILE__) / "views"
  end

  class CookiesController < Testing
    
    def store_cookies
      cookies[:foo] = 'bar'
      cookies.set_cookie(:awesome, 'super-cookie', :domain => 'blog.merbivore.com')
    end
    
    def retrieve_cookies
    end
    
  end
  
  class OverridingSessionCookieDomain < CookiesController
    self._default_cookie_domain = "overridden.merbivore.com"
  end

  class NotOverridingSessionCookieDomain < CookiesController
  end
end
