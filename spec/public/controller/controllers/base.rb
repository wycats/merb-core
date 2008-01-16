module Merb::Test::Fixtures::Controllers
  class Testing < Merb::Controller
    self._template_root = File.dirname(__FILE__) / "views"
  end
  
  class Base < Testing
    def index
      "index"
    end
    
    def hidden
      "Bar"
    end
    hide_action :hidden
        
  end
end