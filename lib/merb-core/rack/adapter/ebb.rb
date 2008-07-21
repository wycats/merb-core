require 'ebb'
module Merb
  
  module Rack

    class Ebb
      # start an Ebb server on given host and port.
      
      # ==== Parameters
      # opts<Hash>:: Options for Ebb (see below).
      #
      # ==== Options (opts)
      # :host<String>:: The hostname that Ebb should serve.
      # :port<Fixnum>:: The port Ebb should bind to.
      # :app:: The application
      def self.start(opts={})
        Merb.logger.warn!("Using Ebb adapter")
        Merb::Dispatcher.use_mutex = false
        th = Thread.new { ::Ebb.start_server(opts[:app], opts) }
        Merb::Server.change_privilege
        th.join
      end
    end
  end
end