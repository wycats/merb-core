require 'webrick'
require 'rack/handler/webrick'

module Merb
  module Rack
    class WEBrick < Adapter
      class << self
        # start server on given host and port.
        def start_server(host, port)
          options = {
            :Port        => port,
            :BindAddress => host,
            :Logger      => Merb.logger,
            :AccessLog   => [
              [Merb.logger, ::WEBrick::AccessLog::COMMON_LOG_FORMAT],
              [Merb.logger, ::WEBrick::AccessLog::REFERER_LOG_FORMAT]
            ]
          }.merge(options)


          server = ::WEBrick::HTTPServer.new(options)
          server.mount("/", ::Rack::Handler::WEBrick, self)
          server.start
        end
      end
    end
  end
end
