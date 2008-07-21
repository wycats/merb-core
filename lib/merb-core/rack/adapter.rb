module Merb
  
  module Rack
    
    class Adapter

      class << self
        # ==== Parameters
        # id<String>:: The identifier of the Rack adapter class to retrieve.
        #
        # ==== Returns.
        # Class:: The adapter class.
        def get(id)
          Object.full_const_get(@adapters[id])
        end

        # Registers a new Rack adapter.
        #
        # ==== Parameters
        # ids<Array>:: Identifiers by which this adapter is recognized by.
        # adapter_class<Class>:: The Rack adapter class.
        def register(ids, adapter_class)
          @adapters ||= Hash.new
          ids.each { |id| @adapters[id] = "Merb::Rack::#{adapter_class}" }
        end
      end # class << self
      
    end # Adapter
    
    # Register some Rack adapters
    Adapter.register %w{ebb},            :Ebb
    Adapter.register %w{emongrel},       :EventedMongrel
    Adapter.register %w{fastcgi fcgi},   :FastCGI
    Adapter.register %w{irb},            :Irb
    Adapter.register %w{mongrel},        :Mongrel  
    Adapter.register %w{runner},         :Runner
    Adapter.register %w{smongrel swift}, :SwiftipliedMongrel
    Adapter.register %w{thin},           :Thin
    Adapter.register %w{thin-turbo},     :ThinTurbo
    Adapter.register %w{webrick},        :WEBrick
    
  end # Rack
end # Merb

