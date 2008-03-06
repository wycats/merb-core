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
      # :port<Fixnum>:: The port Thin should bind to.
      # :app<String>>:: The application name.
      def self.start(opts={})
        Merb.logger.warn!("Using Ebb adapter")
        server = ::Ebb::Server.new(opts[:app], opts)
        server.start
      end
    end
  end
end