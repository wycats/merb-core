

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

  class ClassProvides < Responder; 
    provides :xml
  end

  class LocalProvides < Responder; 
    
    def index
      provides :xml
      render
    end
  end

  class MultiProvides < Responder; 
    
    def index
      provides :html, :js
      render
    end
  end

end