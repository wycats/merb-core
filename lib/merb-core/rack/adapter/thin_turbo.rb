require "thin-turbo"

module Merb

  module Rack

    class ThinTurbo < Thin
      # start a Thin Turbo server on given host and port.

      # ==== Parameters
      # opts<Hash>:: Options for Thin Turbo (see below).
      #
      # ==== Options (opts)
      # :host<String>:: The hostname that Thin Turbo should serve.
      # :port<Fixnum>:: The port Thin Turbo should bind to.
      # :socket<Fixnum>>:: The socket number that thin should bind to.
      # :socket_file<String>>:: The socket file that thin should attach to.
      # :app<String>>:: The application name.
      def self.start(opts={})
        super(opts.merge(:backend => ::Thin::Backends::Turbo))
      end
    end
  end
end
