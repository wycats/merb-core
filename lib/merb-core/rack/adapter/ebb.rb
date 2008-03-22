require 'ebb'
module Merb
  
  module Rack

    class Ebb
      # start an Ebb server on given host and port.
      
      # ==== Parameters
      # opts<Hash>:: Options for Thin (see below).
      #
      # ==== Options (opts)
      # :host<String>:: The hostname that Thin should serve.
      # :port<Fixnum>:: The port Ebb should bind to.
      # :app:: The application
      def self.start(opts={})
        Merb.logger.warn!("Using Ebb adapter")
        ::Ebb.start_server(opts[:app], opts)
      end
    end
  end
end