module Merb  
  module Rack
    class Application
      
      def call(env) 
        begin
          controller = ::Merb::Dispatcher.handle(Merb::Request.new(env))
        rescue Object => e
          return [500, {"Content-Type"=>"text/html"}, e.message + "<br/>" + e.backtrace.join("<br/>")]
        end
        Merb.logger.info "\n\n"
        Merb.logger.flush
        controller.rack_response
      end

      def deferred?(env)
        path = env['PATH_INFO'] ? env['PATH_INFO'].chomp('/') : ""
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
