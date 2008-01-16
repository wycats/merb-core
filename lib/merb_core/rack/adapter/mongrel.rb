gem "mongrel"
require 'mongrel'
require 'rack/handler/mongrel'

module Merb
  module Rack
    class Mongrel < Adapter
      # start server on given host and port.
      def self.start_server(host, port)
        app = new
        server = ::Mongrel::HttpServer.new(host, port)
        server.register('/', ::Rack::Handler::Mongrel.new(app))
        server.run.join
      end
    end
  end
end
