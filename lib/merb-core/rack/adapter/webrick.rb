require 'webrick'
require 'rack/handler/webrick'

module Merb
  module Rack
    class WEBrick < Adapter
      # start WEBrick server on given host and port.
      def self.start_server(host, port)
        app = new
        options = {
          :Port        => port,
          :BindAddress => host,
          :Logger      => Merb.logger,
          :AccessLog   => [
            [Merb.logger, ::WEBrick::AccessLog::COMMON_LOG_FORMAT],
            [Merb.logger, ::WEBrick::AccessLog::REFERER_LOG_FORMAT]
          ]
        }
     
        server = ::WEBrick::HTTPServer.new(options)
        server.mount("/", ::Rack::Handler::WEBrick, app)
        server.start
      end
    end
  end
end
