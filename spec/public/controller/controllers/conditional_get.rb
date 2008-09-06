require "time"

module Merb::Test::Fixtures
  module Controllers
    class Testing < Merb::Controller
      self._template_root = File.dirname(__FILE__) / "views"
    end

    class ConditionalGet < Testing
      def etag
        self.etag = "39791e6fb09"
        "can has etag"
      end

      def last_modified
        self.last_modified = Time.at(7000)
        "can has last-modified"
      end
    end
  end
end
