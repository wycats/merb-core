require "time"

module Merb::Test::Fixtures
  module Controllers
    class Testing < Merb::Controller
      self._template_root = File.dirname(__FILE__) / "views"
    end

    class ConditionalGet < Testing
      def sets_etag
        self.etag = "39791e6fb09"
        "can has etag"
      end

      def sets_last_modified
        self.last_modified = Time.at(7000)
        "can has last-modified"
      end

      def superfresh
        self.etag          = "39791e6fb09"
        self.last_modified = Time.at(7000)
        
        "can has fresh request"
      end

      def stale
        self.etag          = "1234567678"
        self.last_modified = Time.at(9000)
        
        "can has stale request"
      end
    end
  end
end
