require "thin"

module Merb

  module Rack

    class Thin < Merb::Rack::AbstractAdapter
      # start a Thin server on given host and port.

      def self.new_server(port)
        Merb::Dispatcher.use_mutex = false
        
        if @opts[:socket] || @opts[:socket_file]
          socket = port.to_s
          socket_file = @opts[:socket_file] || "#{Merb.root}/log/merb.#{socket}.sock"
          Merb.logger.warn!("Using Thin adapter with socket file #{socket_file}.")
          @server = ::Thin::Server.new(socket_file, @opts[:app], @opts)
        else
          Merb.logger.warn!("Using Thin adapter on host #{@opts[:host]} and port #{port}.")
          if @opts[:host].include?('/')
            @opts[:host] = "#{@opts[:host]}-#{port}"
          end
          @server = ::Thin::Server.new(@opts[:host], port, @opts[:app], @opts)
        end
      end

      def self.start_server
        ::Thin::Logging.silent = true
        @server.start
      end
      
      def self.stop(status = 0)
        @server.stop
      end
    end
  end
end