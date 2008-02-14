require 'mongrel'
require 'merb-core/rack/handler/mongrel'
module Merb

  module Rack

    class Mongrel
      # start server on given host and port.
      def self.start(opts={})
        Merb.logger.info("Using Mongrel adapter") if self == Merb::Rack::Mongrel
        Merb.logger.flush
        server = ::Mongrel::HttpServer.new(opts[:host], opts[:port])
        server.register('/', ::Merb::Rack::Handler::Mongrel.new(opts[:app]))
        server.run.join
      end
    end
  end
end