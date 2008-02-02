require 'mongrel'
require 'rack/handler/mongrel'

# DOC: Ezra Zygmuntowicz FAILED
module Merb

  # DOC: Ezra Zygmuntowicz FAILED
  module Rack

    # DOC: Ezra Zygmuntowicz FAILED
    class Mongrel
      # start server on given host and port.

      # DOC: Ezra Zygmuntowicz FAILED
      def self.start(opts={})
        server = ::Mongrel::HttpServer.new(opts[:host], opts[:port])
        server.register('/', ::Rack::Handler::Mongrel.new(opts[:app]))
        server.run.join
      end
    end
  end
end