module Merb::Test::Fixtures::Controllers
  class Testing < Merb::Controller
    self._template_root = File.dirname(__FILE__) / "views"
  end


  class Responder < Testing
    def index
      render
    end
  end


  class HtmlDefault < Responder; end


  class ClassProvides < Responder
    provides :xml
  end


  class LocalProvides < Responder
    def index
      provides :xml
      render
    end
  end


  class MultiProvides < Responder
    def index
      provides :html, :js
      render
    end
  end

  class ClassAndLocalProvides < Responder
    provides :html    
    def index
      provides :xml
      render
    end
  end

  class ClassOnlyProvides < Responder
    only_provides :text, :xml

    def index
      "nothing"
    end
  end


  class OnlyProvides < Responder
    def index
      only_provides :text, :xml
      "nothing"
    end
  end

  class ClassDoesntProvides < Responder
    provides :xml
    does_not_provide :html

    def index
      "nothing"
    end
  end


  class DoesntProvide < Responder
    def index
      provides :xml
      does_not_provide :html
      "nothing"
    end
  end


  class FooFormatProvides < Responder
    only_provides :foo

    def index
      render "nothing"
    end

    def show
      headers["Content-Language"] = 'nl'
      headers["Biz"] = "buzz"
      render "nothing"
    end
  end
end
