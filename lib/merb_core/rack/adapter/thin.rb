require 'thin'

module Merb
  module Rack
    class Mongrel < Adapter
      class << self
        # start server on given host and port.
        def start_server(host, port)
          server = ::Thin::Server.new(host, port, self)
          server.silent = true
          server.timeout = 3
          server.start!
        end
      end
    end
  end
end
