require 'mongrel'
require 'merb-core/rack/handler/mongrel'
module Merb

  module Rack

    class Mongrel
      # start server on given host and port.
      
      # ==== Parameters
      # opts<Hash>:: Options for Mongrel (see below).
      #
      # ==== Options (opts)
      # :host<String>:: The hostname that Mongrel should serve.
      # :port<Fixnum>:: The port Mongrel should bind to.
      # :app<String>>:: The application name.
      def self.start(opts={})
        $CHILDREN ||= []
        
        pids = {}
        port = opts[:port].to_i
        pid = nil
        
        0.upto(3) do |i|          
          pid = Kernel.fork
          start_at_port(port + i, opts) unless pid

          # pid means we're in the parent, which means continue the loop
          break unless pid
          
          $CHILDREN << pid
          pids[port + i] = pid
        end

        # pid means we're in the parent, so start watching the children
        # no pid means we're in a child, so just move on
        return unless pid

        0.upto(3) do |i|
          Thread.new do
            loop do
              pid = pids[port + i]
              _, status = Process.wait2(pid)
              $CHILDREN.delete(pid)
              new_pid = Kernel.fork do
                start_at_port(port + i, opts)
              end
              $CHILDREN << new_pid
              pids[port + i] = new_pid
            end
          end
        end
        
        sleep
        
      end
      
      def self.start_at_port(port, opts)
        Merb::Server.store_pid(port)
        Merb.logger = Merb::Logger.new(Merb.log_file(port), Merb::Config[:log_level], Merb::Config[:log_delimiter], Merb::Config[:log_auto_flush])
        Merb.logger.warn!("Starting mongrel at port #{port}")
        server = ::Mongrel::HttpServer.new(opts[:host], port)
        Merb::Server.change_privilege
        server.register('/', ::Merb::Rack::Handler::Mongrel.new(opts[:app]))
        server.run.join
      end
      
    end
    
  end
end