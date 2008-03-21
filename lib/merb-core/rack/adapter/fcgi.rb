module Merb
  module Rack
    
    class FastCGI
      # ==== Parameters
      # opts<Hash>:: Options for FastCGI (see below).
      #
      # ==== Options (opts)
      # :app<String>>:: The application name.
      def self.start(opts={})
        Merb.logger.warn!("Using FastCGI adapter")
        ::Rack::Handler::FastCGI.run(opts[:app], opts)
      end
    end
  end
end