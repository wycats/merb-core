module Merb::Test::Fixtures
  module Controllers
    class Testing < Merb::Controller
      self._template_root = File.dirname(__FILE__) / "views"
    end

    module Inclusion
      def self.included(base)
        base.show_action(:baz)
      end

      def baz
        "baz"
      end

      def bat
        "bat"
      end
    end

    class Base < Testing
      include Inclusion

      def index
        self.status = :ok
        "index"
      end

      def hidden
        "Bar"
      end
      hide_action :hidden
    end
    
    class FilteredParams < Testing
      def index
        "Index"
      end
      
      def self._filter_params(params)
        params.reject {|k,v| k == "password" }
      end
    end

    class SetStatus < Testing
      def index
        self.status = "awesome"
      end
    end
    
    class DispatchCallbacks < Testing
      
      attr_accessor :called_before, :called_after
      
      self._before_dispatch_callbacks << lambda { |c| c.called_before = true }
      self._after_dispatch_callbacks  << lambda { |c| c.called_after  = true }
      
      def index
        "index"
      end
      
    end

  end
end
