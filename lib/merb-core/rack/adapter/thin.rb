require 'thin'
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
      # :app<String>>:: The application name.
      def self.start(opts={})
        Merb.logger.warn!("Using Thin adapter")
        if opts[:host].include?('/')
          opts[:host] =  "#{opts[:host]}-#{opts[:port]}"
        end  
        server = ::Thin::Server.new(opts[:host], opts[:port], opts[:app])
        ::Thin::Logging.silent = true
        server.start!
      end
    end
  end
end