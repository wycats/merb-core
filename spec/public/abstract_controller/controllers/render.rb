

module Merb::Test::Fixtures

  module Abstract
    
    class Testing < Merb::AbstractController
      self._template_root = File.dirname(__FILE__) / "views"
    end

    class RenderString < Testing
      
      def index
        render "the index"
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
    
    class RenderStringDynamicLayout < RenderString
      layout :determine_layout
      
      def alt_index
        render "the alt index"
      end
      
      def determine_layout
        action_name.index('alt') == 0 ? 'alt' : 'custom'
      end
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
    
    class RenderTemplateCustomLocation < RenderTemplate      
      def _template_location(action, type = nil, controller = controller_name)  
        "wonderful/#{action}"
      end
    end
    
    class RenderTemplateMultipleRoots < RenderTemplate
      self._template_roots << [File.dirname(__FILE__) / "alt_views", :_template_location]
      
      def show
        render :layout=>false
      end
    end

    class RenderTemplateMultipleRootsAndCustomLocation < RenderTemplate
      self._template_roots = [[File.dirname(__FILE__) / "alt_views", :_custom_template_location]]
      
      def _custom_template_location(action, type = nil, controller = controller_name)
        "#{self.class.name.split('::')[-1].to_const_path}/#{action}"
      end
    end
    
    class RenderTemplateMultipleRootsInherited < RenderTemplateMultipleRootsAndCustomLocation
    end
  end
end