module Merb
  
  module Rack
    
    class FastCGI

      def self.start(opts={})
        Merb.logger.info("Using FastCGI adapter")
        Merb.logger.flush
        Rack::Handler::FastCGI.run(opts[:app])
      end
    end
  end
end