module Merb::Test::Fixtures
  class ControllerTesting < Merb::Controller
    self._template_root = File.dirname(__FILE__) / "views"
  end
  
  class TestBase < ControllerTesting
    def index
      "index"
    end
    
    def hidden
      "Bar"
    end
    hide_action :hidden
        
  end
end