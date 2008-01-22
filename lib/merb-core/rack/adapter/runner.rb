module Merb
  module Rack
    class Runner
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


