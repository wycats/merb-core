module Merb::Test::Fixtures::Controllers

  class Testing < Merb::Controller
    self._template_root = File.dirname(__FILE__) / "views"
  end

  class CookiesController < Testing
  end
  
  class OverridingSessionCookieDomain < CookiesController
    self._session_cookie_domain = "overridden.merbivore.com"
  end

  class NotOverridingSessionCookieDomain < CookiesController
  end
end
