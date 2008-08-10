class Application < Merb::Controller
end

module Merb::Test::Fixtures
  module Controllers
    class Testing < Merb::Controller
      self._template_root = File.dirname(__FILE__) / "views"
    end

    class DispatchTo < Testing
      def index
        "Dispatched"
      end
    end
    
    class NotAController
      def index
        "Dispatched"
      end
    end
    
    class RaiseGone < Testing
      def index
        raise Gone
      end
    end

    class RaiseLoadError < Merb::Controller
      def index
        raise LoadError, "In the controller"
      end
    end

  end
end
