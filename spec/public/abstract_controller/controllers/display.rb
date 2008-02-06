

module Merb::Test::Fixtures

  module Abstract
    
    class SomeModel; end
    
    class Testing < Merb::AbstractController
      self._template_root = File.dirname(__FILE__) / "views"
    end
    
    class DisplayObject < Testing
      def index
        @obj = SomeModel.new
        display @obj
      end
    end
    
    class DisplayObjectWithAction < Testing
      def create
        @obj = SomeModel.new
        display @obj, :new
      end
    end
    
    class DisplayObjectWithPath < Testing
      def index
        @obj = SomeModel.new
        display @obj, "test_display/foo.html"
      end
    end
    
  end

end