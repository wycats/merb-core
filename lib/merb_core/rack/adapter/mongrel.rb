require 'mongrel'
require 'rack/handler/mongrel'

module Merb
  module Rack
    class Mongrel < Adapter
      class << self
        # start server on given host and port.
        def start_server(host, port)
          server = ::Mongrel::HttpServer.new(host, port)
          server.register('/', ::Rack::Handler::Mongrel.new(self))
          server.run.join
        end
      end
    end
  end
end
