

module Merb::Test::Fixtures::Controllers
  
  class SomeModel
    def to_xml; "<XML:Model />" end
  end
  
  class Testing < Merb::Controller
    self._template_root = File.dirname(__FILE__) / "views"
  end
  
  class Display < Testing
    
    def index
      @obj = SomeModel.new
      display @obj
    end
  end

  class DisplayHtmlDefault < Display; end

  class DisplayClassProvides < Display
    provides :xml
  end

  class DisplayLocalProvides < Display
    
    def index
      @obj = SomeModel.new
      provides :xml
      display @obj
    end
  end
  
  class DisplayWithTemplate < Display
    layout :custom
  end
  
  class DisplayWithTemplateArgument < Display
    def index
      @obj = SomeModel.new
      display @obj, :layout => :custom_arg
    end
    
    def index_by_arg
      @obj = SomeModel.new
      display @obj, "merb/test/fixtures/controllers/display_with_template_argument/index.html"
    end
  end
end