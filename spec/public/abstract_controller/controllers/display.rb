

module Merb::Test::Fixtures

  module Abstract
    
    class Testing < Merb::AbstractController
      self._template_root = File.dirname(__FILE__) / "views"
    end
    
    class DisplayObject < Testing      
      def index
        display @obj
      end
    end
    
    class DisplayObjectWithSymbol < Testing
      def create
        display @obj, :new
      end
    end
    
    class DisplayObjectWithString < Testing
      def index
        display @obj, "full/path/to/template"
      end
    end
    
  end

end