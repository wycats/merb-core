module Merb::Test::Fixtures
  module Abstract
  
    class HelperTesting < Merb::AbstractController
      self._template_root = File.dirname(__FILE__) / "views"
      
      def _template_location(context, type = nil, controller = controller_name)
        "helpers/#{File.basename(controller)}/#{context}"
      end
      
      def index
        render
      end
    end
    
    class Capture < HelperTesting
    end
    
    class CaptureWithArgs < HelperTesting
    end
    
    class CaptureEq < HelperTesting
      def helper_using_capture(&blk)
        "Beginning... #{capture(&blk)}... Done"
      end
    end

    module ConcatHelper
      def concatter(&blk)
        concat("Concat", blk.binding)
      end
    end
    
    class Concat < HelperTesting
      def index
        render
      end
    end
       
  end
end