module Merb::Test::Fixtures
  class ControllerTesting < Merb::Controller
    self._template_root = File.dirname(__FILE__) / "views"
  end
  
  class TestResponder < ControllerTesting
    def index
      render
    end
  end
  
  class TestHtmlDefault < TestResponder; end
  
  class TestClassProvides < TestResponder; 
    provides :xml
  end
  
  class TestLocalProvides < TestResponder; 
    def index
      provides :xml
      render
    end
  end
  
end