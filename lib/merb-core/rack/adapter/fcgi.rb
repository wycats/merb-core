module Merb
  module Rack
    
    class FastCGI
      # ==== Parameters
      # opts<Hash>:: Options for FastCGI (see below).
      #
      # ==== Options (opts)
      # :app<String>>:: The application name.
      def self.start(opts={})
        Merb.logger.info("Using FastCGI adapter")
        Merb.logger.flush
        Rack::Handler::FastCGI.run(opts[:app])
      end
    end
  end
end