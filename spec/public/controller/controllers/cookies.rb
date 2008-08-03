module Merb::Test::Fixtures::Controllers

  class Testing < Merb::Controller
    self._template_root = File.dirname(__FILE__) / "views"
  end

  class CookiesController < Testing

    def sets_cookie
      "sets_cookie"
    end

    def sets_cookie_explicitly
      "sets_cookie_explicitly"
    end

    def deletes_cookie
      "deletes_cookie"
    end

    def deletes_cookie_explicitly
      "deletes_cookie_explicitly"
    end
    
  end
end
