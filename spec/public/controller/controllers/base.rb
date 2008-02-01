

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
        "index"
      end

      def hidden
        "Bar"
      end
      hide_action :hidden
    end

    class BeforeHook < Testing
      add_hook(:before_dispatch) do
        @stuff = "Proc"
      end

      def index
        @stuff
      end
    end

    class BeforeHookInherit < BeforeHook
      
      def index
        @stuff
      end
    end

    class BeforeHookSymbol < BeforeHook
      add_hook :before_dispatch, :stuff
      
      def index
        "#{@stuff} #{@stuff2}"
      end

      private
      
      def stuff
        @stuff2 = "Symbol"
      end
    end

    class AfterHook < Testing
      add_hook(:after_dispatch) do
        @body = "Proc"
      end

      def index
        ""
      end
    end

    class AfterHookSymbol < AfterHook
      add_hook(:after_dispatch, :stuff)

      def index
        ""
      end
    
      private
      
      def stuff
        @body += " Symbol"
      end
    end
  end
end