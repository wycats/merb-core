module Merb
  module Rack
    class Middleware
      
      def initialize(app)
        @app = app
      end
      
      def deferred?(env)
        @app.deferred?(env)
      end
  
      def call(env)
        @app.call(env)
      end
      
    end
  end
end

