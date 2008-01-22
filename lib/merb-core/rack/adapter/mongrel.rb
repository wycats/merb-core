require 'mongrel'
require 'rack/handler/mongrel'

module Merb
  module Rack
    class Mongrel
      # start server on given host and port.
      def self.start(opts={})
        server = ::Mongrel::HttpServer.new(opts[:host], opts[:port])
        server.register('/', ::Rack::Handler::Mongrel.new(opts[:app]))
        server.run.join
      end
    end
  end
end
