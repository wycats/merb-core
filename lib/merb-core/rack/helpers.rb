module Merb
  module Rack
    module Helpers
      
      # Generates a Rack redirection response based on the params.
      # 
      # ==== Parameters
      # url<String>:: the URL to redirect to.
      # options<Hash>:: An options hash (see below)
      # 
      # ==== Options (options)
      # :permanent<Boolean>::
      #   indicates a permanent (301) or temporary (302) redirect.
      # :status<Integer>::
      #   the status of the response, defaults to 302.
      # 
      # @api public
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