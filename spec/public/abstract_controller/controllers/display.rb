

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

    class DisplayObjectWithPathViaOpts < Testing
      def index
        @obj = SomeModel.new
        display @obj, :template => "test_display/foo.html"
      end
    end
    
    class DisplayObjectWithMultipleRoots < DisplayObject
      self._template_roots << [File.dirname(__FILE__) / "alt_views", :_template_location]
      
      def show
        @obj = SomeModel.new
        display @obj, nil, :layout=>"alt"
      end
      
      def another
        @obj = SomeModel.new
        display @obj, "test_display/foo.html", :layout=>false
      end
      
      def wonderful
        true
      end
    end
  end

end
