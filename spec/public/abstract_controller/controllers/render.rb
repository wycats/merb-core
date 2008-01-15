module Merb::Test::Fixtures
  class AbstractTesting < Merb::AbstractController
    self._template_root = File.dirname(__FILE__) / "views"
  end

  class TestRenderString < AbstractTesting
    def index
      render "index"
    end
  end

  class TestRenderStringCustomLayout < TestRenderString
    layout :custom
  end
  
  class TestRenderStringAppLayout < TestRenderString;  end  

  class TestRenderStringControllerLayout < TestRenderString;  end
  
  class TestRenderTemplate < AbstractTesting
    def index
      render
    end
  end
  
  class TestRenderTemplateCustomLayout < TestRenderString
    layout :custom
  end
  
  class TestRenderTemplateAppLayout < TestRenderString;  end  
  
  class TestRenderTemplateControllerLayout < TestRenderString;  end  

end