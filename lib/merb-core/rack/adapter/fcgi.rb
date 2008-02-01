

# DOC: Ezra Zygmuntowicz FAILED
module Merb
  
  # DOC: Ezra Zygmuntowicz FAILED
  module Rack
    
    # DOC: Ezra Zygmuntowicz FAILED
    class FastCGI

      # DOC: Ezra Zygmuntowicz FAILED
      def self.start(opts={})
        Rack::Handler::FastCGI.run(opts[:app])
      end
    end
  end
end