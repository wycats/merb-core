require 'thin'
module Merb
  
  module Rack

    class Thin
      # start a Thin server on given host and port.
      def self.start(opts={})
        Merb.logger.info("Using Thin adapter")
        Merb.logger.flush
        server = ::Thin::Server.new(opts[:host], opts[:port], opts[:app])
        server.silent = true
        server.start!
      end
    end
  end
end