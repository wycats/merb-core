require 'thin'

module Merb
  module Rack
    class Thin < Adapter
      # start a Thin server on given host and port.
      def self.start_server(host, port)
        app = new
        server = ::Thin::Server.new(host, port.to_i, app)
        server.silent = true
        server.timeout = 3
        server.start!
      end
    end
  end
end
