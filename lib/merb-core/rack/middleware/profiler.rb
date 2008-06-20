module Merb
  module Rack
    class Profiler < Merb::Rack::Middleware

      def initialize(app, min=1, iter=1)
        super(app)
        @min, @iter = min, iter
      end

      def call(env)
        __profile__("profile_output", @min, @iter) do
          @app.call(env)
        end
      end

      
    end
  end
end