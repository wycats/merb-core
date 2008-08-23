module Merb  
  module Rack
    class Application
      
      def call(env) 
        begin
          controller = ::Merb::Dispatcher.handle(Merb::Request.new(env))
        rescue Object => e
          return [500, {Merb::Const::CONTENT_TYPE => "text/html"}, e.message + "<br/>" + e.backtrace.join("<br/>")]
        end
        Merb.logger.info "\n\n"
        Merb.logger.flush

        unless controller.headers[Merb::Const::DATE]
          require "time"
          controller.headers[Merb::Const::DATE] = Time.now.rfc2822.to_s
        end
        controller.rack_response
      end

      def deferred?(env)
        path = env[Merb::Const::PATH_INFO] ? env[Merb::Const::PATH_INFO].chomp('/') : ""
        if path =~ Merb.deferred_actions
          Merb.logger.info! "Deferring Request: #{path}"
          true
        else
          false
        end        
      end # deferred?(env)
    end # Application
  end # Rack
end # Merb
