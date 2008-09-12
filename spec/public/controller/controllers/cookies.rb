module Merb::Test::Fixtures::Controllers

  class Testing < Merb::Controller
    self._template_root = File.dirname(__FILE__) / "views"
  end

  class CookiesController < Testing
    
    def store_cookies
      cookies.set_cookie(:awesome,   'super-cookie', :domain  => 'blog.merbivore.com')
      cookies[:foo] = 'bar'
      cookies.set_cookie(:oldcookie, 'this is really old', :expires => Time.utc(2020))
      cookies.set_cookie(:safecook,  'no-hackers-here', :secure => true)
    end
    
    def destroy_cookies
      cookies.delete(:foo)
    end
    
    def retrieve_cookies
    end
    
  end
  
  class OverridingDefaultCookieDomain < CookiesController
    self._default_cookie_domain = "overridden.merbivore.com"
  end

  class NotOverridingDefaultCookieDomain < CookiesController
  end
  
  class EmptyDefaultCookieDomain < CookiesController
    self._default_cookie_domain = ''
  end
  
end
