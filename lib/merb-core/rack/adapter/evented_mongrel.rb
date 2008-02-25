require 'swiftcore/evented_mongrel'
module Merb
  module Rack

    class EventedMongrel < Mongrel
      # Starts Mongrel as evented.
      #
      # ==== Parameters
      # opts<Hash>:: Options for Mongrel (see below).
      #
      # ==== Options (opts)
      # :host<String>:: The hostname that Mongrel should serve.
      # :port<Fixnum>:: The port Mongrel should bind to.
      # :app<String>>:: The application name.
      def self.start(opts={})
        Merb.logger.info("Using EventedMongrel adapter")
        super
      end
    end
  end
end