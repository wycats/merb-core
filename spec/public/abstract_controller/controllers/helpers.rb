module Merb::Test::Fixtures
  module Abstract
  
    class HelperTesting < Merb::AbstractController
      self._template_root = File.dirname(__FILE__) / "views"
      
      def _template_location(action, type = nil, controller = controller_name)
        "helpers/#{File.basename(controller)}/#{action}"
      end
    end
    
    class Capture < HelperTesting
      def index
        render
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