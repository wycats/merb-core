module Merb
  module Rack
    class MerbDispatch
      
      def call(env) 
        begin
          controller = ::Merb::Dispatcher.handle(env)
        rescue Object => e
          return [500, {"Content-Type"=>"text/html"}, e.message + "<br/>" + e.backtrace.join("<br/>")]
        end
        Merb.logger.info "\n\n"
        Merb.logger.flush
        [controller.status, controller.headers, controller.body]
      end
      
    end
  end
end