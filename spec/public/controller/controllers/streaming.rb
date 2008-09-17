module Merb::Test::Fixtures
  module Controllers
    class Testing < Merb::Controller
      self._template_root = File.dirname(__FILE__) / "views"
    end

    class Streaming < Testing
      def x_accel_redirect
        nginx_send_file "/protected/content.pdf", "application/pdf"
      end

      def x_accel_redirect_with_default_content_type
        nginx_send_file "/protected/content.pdf"
      end

    end
  end
end
