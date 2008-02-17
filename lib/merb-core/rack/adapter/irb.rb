module Merb
  module Rack
    class Console
      def params() {} end
      
      def url(name, params={})
        Merb::Router.generate(name, params)
      end
      
      def reload!
        Merb::BootLoader::ReloadClasses.reload
      end
      
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

    class Irb

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