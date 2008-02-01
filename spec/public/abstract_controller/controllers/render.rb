

module Merb::Test::Fixtures

  module Abstract
    
    class Testing < Merb::AbstractController
      self._template_root = File.dirname(__FILE__) / "views"
    end

    class RenderString < Testing
      
      def index
        render "index"
      end
    end

    class RenderStringCustomLayout < RenderString
      layout :custom
    end

    class RenderStringAppLayout < RenderString
      self._template_root = File.dirname(__FILE__) / "alt_views"      
    end

    class RenderStringControllerLayout < RenderString
      self._template_root = File.dirname(__FILE__) / "alt_views"
    end

    class RenderTemplate < Testing
      
      def index
        render
      end
    end

    class RenderTemplateCustomLayout < RenderString
      layout :custom
    end

    class RenderTemplateAppLayout < RenderString
      self._template_root = File.dirname(__FILE__) / "alt_views"      
    end

    class RenderTemplateControllerLayout < RenderString
      self._template_root = File.dirname(__FILE__) / "alt_views"      
    end  
  end
end