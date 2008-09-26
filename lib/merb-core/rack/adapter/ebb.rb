require 'ebb'
module Merb
  
  module Rack

    class Ebb < Merb::Rack::AbstractAdapter
      # start an Ebb server on given host and port.
      
      def self.new_server(port)
        Merb::Dispatcher.use_mutex = false
        opts = @opts.merge(:port => port)
        @th = Thread.new { Thread.current[:server] = ::Ebb.start_server(opts[:app], opts) }
      end
      
      def self.start_server
        @th.join
      end
      
      def self.stop(status = 0)
        ::Ebb.stop_server
      end
    end
  end
end