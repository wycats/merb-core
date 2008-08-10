require "thin"

module Merb

  module Rack

    class Thin
      # start a Thin server on given host and port.

      # ==== Parameters
      # opts<Hash>:: Options for Thin (see below).
      #
      # ==== Options (opts)
      # :host<String>:: The hostname that Thin should serve.
      # :port<Fixnum>:: The port Thin should bind to.
      # :socket<Fixnum>>:: The socket number that thin should bind to.
      # :socket_file<String>>:: The socket file that thin should attach to.
      # :app<String>>:: The application name.
      def self.start(opts={})
        Merb::Dispatcher.use_mutex = false
        if opts[:socket] || opts[:socket_file]
          socket = opts[:socket] || "0"
          socket_file = opts[:socket_file] || "#{Merb.root}/log/merb.#{socket}.sock"
          Merb.logger.warn!("Using Thin adapter with socket file #{socket_file}.")
          server = ::Thin::Server.new(socket_file, opts[:app], opts)
        else
          Merb.logger.warn!("Using Thin adapter on host #{opts[:host]} and port #{opts[:port]}.")
          if opts[:host].include?('/')
            opts[:host] = "#{opts[:host]}-#{opts[:port]}"
          end
          server = ::Thin::Server.new(opts[:host], opts[:port].to_i, opts[:app], opts)
        end
        Merb::Server.change_privilege
        ::Thin::Logging.silent = true
        server.start
      end
    end
  end
end