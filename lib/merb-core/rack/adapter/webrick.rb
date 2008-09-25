require 'webrick'
require 'webrick/utils'
require 'rack/handler/webrick'
module Merb
  module Rack

    class WEBrick < Merb::Rack::AbstractAdapter
      
      class << self
        attr_accessor :server
      end
      
      def self.new_server(port)
        options = {
          :Port        => port,
          :BindAddress => @opts[:host],
          :Logger      => Merb.logger,
          :AccessLog   => [
            [Merb.logger, ::WEBrick::AccessLog::COMMON_LOG_FORMAT],
            [Merb.logger, ::WEBrick::AccessLog::REFERER_LOG_FORMAT]
          ]
        }

        sockets = ::WEBrick::Utils.create_listeners nil, port
        @server = ::WEBrick::HTTPServer.new(options.merge(:DoNotListen => true))
        @server.listeners.replace sockets
      end
      
      def self.start_server
        @server.mount("/", ::Rack::Handler::WEBrick, @opts[:app])
        @server.start
        exit(@status)
      end
      
      def self.stop(status = 0)
        @status = status
        @server.shutdown
      end
      
      def self.exit_process(status = 0)
      end      
      
      # start WEBrick server on given host and port.
      
      # ==== Parameters
      # opts<Hash>:: Options for WEBrick (see below).
      #
      # ==== Options (opts)
      # :host<String>:: The hostname that WEBrick should serve.
      # :port<Fixnum>:: The port WEBrick should bind to.
      # :app<String>>:: The application name.
      # def self.start(opts={})
      #   Merb.logger.warn!("Using Webrick adapter")
      # 
      #   options = {
      #     :Port        => opts[:port],
      #     :BindAddress => opts[:host],
      #     :Logger      => Merb.logger,
      #     :AccessLog   => [
      #       [Merb.logger, ::WEBrick::AccessLog::COMMON_LOG_FORMAT],
      #       [Merb.logger, ::WEBrick::AccessLog::REFERER_LOG_FORMAT]
      #     ]
      #   }
      #      
      #   server = ::WEBrick::HTTPServer.new(options)
      #   Merb::Server.change_privilege
      #   server.mount("/", ::Rack::Handler::WEBrick, opts[:app])
      #   server.start
      # end
    end
  end
end