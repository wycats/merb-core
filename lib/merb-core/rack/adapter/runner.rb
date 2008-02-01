

# DOC: Ezra Zygmuntowicz FAILED
module Merb
  
  # DOC: Ezra Zygmuntowicz FAILED
  module Rack
    
    # DOC: Ezra Zygmuntowicz FAILED
    class Runner

      # DOC: Ezra Zygmuntowicz FAILED
      def self.start(opts={})
        if opts[:runner_code]
          if File.exists?(opts[:runner_code])
            eval(File.read(opts[:runner_code]), TOPLEVEL_BINDING)
          else
            eval(opts[:runner_code], TOPLEVEL_BINDING)
          end
          exit!
        end  
      end
    end
  end
end