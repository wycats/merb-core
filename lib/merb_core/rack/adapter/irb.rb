

module Merb
  module Rack
    class Irb
      def self.start_server(host, port)
        _merb = Class.new do
          class << self
            def params() {} end
          end  
          def self.show_routes(all_opts = false)
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
      
        Object.send(:define_method, :merb) {
          _merb
        }  
        ARGV.clear # Avoid passing args to IRB 
        require 'irb' 
        require 'irb/completion' 
        def exit
          exit!
        end   
        if File.exists? ".irbrc"
          ENV['IRBRC'] = ".irbrc"
        end
        IRB.start
        exit!
      end
    end
  end
end



