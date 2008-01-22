module Merb
  module Rack
    class FastCGI
      def self.start(opts={})
        Rack::Handler::FastCGI.run(opts[:app])
      end
    end
  end
end
