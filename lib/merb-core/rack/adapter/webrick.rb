require 'webrick'
require 'rack/handler/webrick'
module Merb
  module Rack

    class WEBrick
      # start WEBrick server on given host and port.
      def self.start(opts={})
        Merb.logger.info("Using Webrick adapter")
        Merb.logger.flush
      
        options = {
          :Port        => opts[:port],
          :BindAddress => opts[:host],
          :Logger      => Merb.logger,
          :AccessLog   => [
            [Merb.logger, ::WEBrick::AccessLog::COMMON_LOG_FORMAT],
            [Merb.logger, ::WEBrick::AccessLog::REFERER_LOG_FORMAT]
          ]
        }
     
        server = ::WEBrick::HTTPServer.new(options)
        server.mount("/", ::Rack::Handler::WEBrick, opts[:app])
        server.start
      end
    end
  end
end