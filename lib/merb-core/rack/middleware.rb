module Merb
  module Rack
    class Middleware
      
      def initialize(app)
        @app = app
      end
      
      def deferred?(env)
        path = env['PATH_INFO'] ? env['PATH_INFO'].chomp('/') : ""
        if path =~ Merb.deferred_actions
          Merb.logger.info! "Deferring Request: #{path}"
          true
        else
          false
        end
      end
  
      def call(env)
        @app.call(env)
      end
      
    end
  end
end

