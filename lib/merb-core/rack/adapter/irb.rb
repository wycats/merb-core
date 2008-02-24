module Merb
  module Rack
    class Console
      # ==== Parameters
      # name<~to_sym, Hash>:: The name of the route to generate.
      # params<Hash>:: The params to use in the route generation.
      #
      # ==== Returns
      # String:: The generated URL.
      #
      # ==== Alternatives
      # If name is a hash, it will be merged with params.      
      def url(name, params={})
        Merb::Router.generate(name, params)
      end
      
      # Reloads classes using Merb::BootLoader::ReloadClasses.
      def reload!
        Merb::BootLoader::ReloadClasses.reload
      end
      
      # Prints all routes for the application.
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
      # ==== Parameters
      # opts<Hash>:
      #   Options for IRB. Currently this is not used by the IRB adapter.
      #
      # ==== Notes
      # If the +.irbrc+ file exists, it will be loaded into the IRBRC
      # environment variable.
      def self.start(opts={})
        m = Merb::Rack::Console.new
        Object.send(:define_method, :merb) { m }  
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