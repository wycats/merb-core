

# DOC: Ezra Zygmuntowicz FAILED
module Merb
  
  # DOC: Ezra Zygmuntowicz FAILED
  module Rack
    
    # DOC: Ezra Zygmuntowicz FAILED
    class Console

      # DOC: Ezra Zygmuntowicz FAILED
      def params() {} end

      # DOC: Ezra Zygmuntowicz FAILED
      def show_routes
        seen = []
        unless Merb::Router.named_routes.empty?
          puts "Named Routes"
          Merb::Router.named_routes.each do |name,route|
            puts "  #{name}: #{route}"
            seen << route
          end
        end
        puts "Anonymous Routes"
        (Merb::Router.routes - seen).each do |route|
          puts "  #{route}"
        end
        nil
      end
    end

    # DOC: Ezra Zygmuntowicz FAILED
    class Irb

      # DOC: Ezra Zygmuntowicz FAILED
      def self.start(opts={})
        m = Merb::Rack::Console.new
        Object.send(:define_method, :merb) {
          m
        }  
        ARGV.clear # Avoid passing args to IRB 
        require 'irb' 
        require 'irb/completion' 
        if File.exists? ".irbrc"
          ENV['IRBRC'] = ".irbrc"
        end
        IRB.start
        exit
      end
    end
  end
end