module Merb::Test::Fixtures::Controller
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
  
end