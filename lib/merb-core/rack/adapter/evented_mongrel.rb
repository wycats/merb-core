require 'swiftcore/evented_mongrel'
module Merb
  
  module Rack

    class EventedMongrel < Mongrel
      def self.start(opts={})
        Merb.logger.info("Using EventedMongrel adapter")
        super
      end
    end
  end
end