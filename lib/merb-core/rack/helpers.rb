module Merb
  module Rack
    module Helpers
      
      def self.redirect(url, options = {})
        # Build the rack array
        status   = options.delete(:status)
        status ||= options[:permanent] ? 301 : 302
        
        Merb.logger.info("Dispatcher redirecting to: #{url} (#{status})")
        Merb.logger.flush
        
        [status, { "Location" => url },
         Merb::Rack::StreamWrapper.new("<html><body>You are being <a href=\"#{url}\">redirected</a>.</body></html>")]
      end
      
    end
  end
end