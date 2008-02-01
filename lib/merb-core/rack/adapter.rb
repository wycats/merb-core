

# DOC: Ezra Zygmuntowicz FAILED
module Merb
  
  # DOC: Ezra Zygmuntowicz FAILED
  module Rack
    
    # DOC: Ezra Zygmuntowicz FAILED
    class Adapter

      class << self

        # DOC: Ezra Zygmuntowicz FAILED
        def get(id)
          Object.full_const_get(@adapters[id])
        end

        # DOC: Ezra Zygmuntowicz FAILED
        def register(ids, adapter_class)
          @adapters ||= Hash.new
          ids.each { |id| @adapters[id] = "Merb::Rack::#{adapter_class}" }
        end
      end # class << self
      
    end # Adapter
    
    # Register some Rack adapters
    Adapter.register %w{emongrel},     :EventedMongrel
    Adapter.register %w{fastcgi fcgi}, :FastCGI
    Adapter.register %w{irb},          :Irb
    Adapter.register %w{mongrel},      :Mongrel  
    Adapter.register %w{runner},       :Runner
    Adapter.register %w{thin},         :Thin
    Adapter.register %w{webrick},      :WEBrick
    
  end # Rack
end # Merb