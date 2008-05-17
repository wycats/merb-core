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
          puts "==== Named routes"
          Merb::Router.named_routes.each do |name,route|
            # something weird happens when you combine sprintf and irb
            puts "Helper     : #{name}"
            meth = $1.upcase if route.conditions[:method].to_s =~ /(get|post|put|delete)/
            puts "HTTP method: #{meth || 'GET'}"
            puts "Route      : #{route}"
            puts "Params     : #{route.params.inspect}"
            puts
            seen << route
          end
        end
        puts "==== Anonymous routes"
        (Merb::Router.routes - seen).each do |route|
          meth = $1.upcase if route.conditions[:method].to_s =~ /(get|post|put|delete)/
          puts "HTTP method: #{meth || 'GET'}"
          puts "Route      : #{route}"
          puts "Params     : #{route.params.inspect}"
          puts
        end
        nil
      end

      # Starts a sandboxed session (delegates to any Merb::Orms::* modules).
      #
      # An ORM should implement Merb::Orms::MyOrm#open_sandbox! to support this.
      # Usually this involves starting a transaction.
      def open_sandbox!
        puts "Loading #{Merb.environment} environment in sandbox (Merb #{Merb::VERSION})"
        puts "Any modifications you make will be rolled back on exit"
        orm_modules.each { |orm| orm.open_sandbox! if orm.respond_to?(:open_sandbox!) }
      end

      # Ends a sandboxed session (delegates to any Merb::Orms::* modules).
      #
      # An ORM should implement Merb::Orms::MyOrm#close_sandbox! to support this.
      # Usually this involves rolling back a transaction.
      def close_sandbox!
        orm_modules.each { |orm| orm.close_sandbox! if orm.respond_to?(:close_sandbox!) }
        puts "Modifications have been rolled back"
      end

      # Explictly show logger output during IRB session
      def trace_log!
        Merb.logger.auto_flush = true
      end

      private

      # ==== Returns
      # Array:: All Merb::Orms::* modules.
      def orm_modules
        if Merb.const_defined?('Orms')
          Merb::Orms.constants.map { |c| Merb::Orms::const_get(c) }
        else
          []
        end
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
        m.extend Merb::Test::RequestHelper
        Object.send(:define_method, :merb) { m }
        ARGV.clear # Avoid passing args to IRB
        m.open_sandbox! if sandboxed?
        require 'irb'
        require 'irb/completion'
        if File.exists? ".irbrc"
          ENV['IRBRC'] = ".irbrc"
        end
        IRB.start
        at_exit do merb.close_sandbox! if sandboxed? end
        exit
      end

      private

      def self.sandboxed?
        Merb::Config[:sandbox]
      end
    end
  end
end
