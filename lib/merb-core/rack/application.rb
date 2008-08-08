module Merb  
  module Rack
    class Application
      
      def call(env) 
        begin
          controller = ::Merb::Dispatcher.handle(env)
        rescue Object => e
          return [500, {"Content-Type"=>"text/html"}, e.message + "<br/>" + e.backtrace.join("<br/>")]
        end
        Merb.logger.info "\n\n"
        Merb.logger.flush
        controller.rack_response
      end
      
    end
  end  
end
