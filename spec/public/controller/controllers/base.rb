

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

  end
end