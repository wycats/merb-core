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
        max_port = Merb::Config[:cluster] ? Merb::Config[:cluster] - 1 : 0
        pid = nil
        
        0.upto(max_port) do |i|          
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

        0.upto(max_port) do |i|
          Thread.new do
            loop do
              pid = pids[port + i]
              begin
                _, status = Process.wait2(pid)
              rescue SystemCallError
              ensure
                Thread.exit if !status || status.exitstatus == 128 || Merb.exiting
              end
              
              new_pid = Kernel.fork
              start_at_port(port + i, opts) unless new_pid
              break unless new_pid
              pids[port + i] = new_pid
              $CHILDREN = pids.values
            end
          end
        end

        sleep
        
      end
      
      def self.stop
        @server.stop(true)
      end
      
      def self.start_at_port(port, opts)
        trap('INT') do
          stop
          puts "\nExiting\n"
          exit
        end
        
        trap('ABRT') do
          stop
          puts "\nExiting\n"
          exit(128)
        end
        
        Merb::Server.store_pid(port)
        Merb.logger = Merb::Logger.new(Merb.log_file(port), Merb::Config[:log_level], Merb::Config[:log_delimiter], Merb::Config[:log_auto_flush])
        Merb.logger.warn!("Starting mongrel at port #{port}")
        
        loop do
          begin
            @server = ::Mongrel::HttpServer.new(opts[:host], port)
          rescue Errno::EADDRINUSE
            puts "\nPort #{port} was still in use. Trying again.\n"
            sleep 0.25
            next
          end
          break
        end
        
        Merb::Server.change_privilege
        @server.register('/', ::Merb::Rack::Handler::Mongrel.new(opts[:app]))
        @server.run.join
      end
      
    end
    
  end
end