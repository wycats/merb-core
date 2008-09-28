require 'mongrel'
require 'merb-core/rack/handler/mongrel'
module Merb

  module Rack

    class Mongrel < Merb::Rack::AbstractAdapter

      def self.stop(status = 0)
        if @server
          begin
            @server.stop(true)
          rescue Mongrel::TimeoutError
            Merb.logger.fatal! "Your process took too long to shut " \
              "down, so mongrel killed it."
          end
          true
        end
      end
      
      def self.new_server(port)
        @server = ::Mongrel::HttpServer.new(@opts[:host], port)
      end
      
      def self.start_server
        @server.register('/', ::Merb::Rack::Handler::Mongrel.new(@opts[:app]))
        @server.run.join
      end
      
    end
    
  end
end