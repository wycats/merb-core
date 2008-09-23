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
        pids = {}
        port = opts[:port].to_i
        
        0.upto(3) do |i|
          
          pid = Kernel.fork do
            start_at_port(port + i, opts)
          end
          
          break unless pid
          
          pids[pid] = port
        end
        
        finished_pid, status = Process.wait2 if pid
        
      end
    end
    
    def self.start_at_port(port, opts)
      Merb.logger.warn!("Using Mongrel adapter")
      server = ::Mongrel::HttpServer.new(opts[:host], port)
      Merb::Server.change_privilege
      server.register('/', ::Merb::Rack::Handler::Mongrel.new(opts[:app]))
      server.run.join
    end
  end
end