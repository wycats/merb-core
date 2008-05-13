module Merb
   module Rack
     class AbstractMiddleware
       
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


module Merb
  
  module Rack

    class Application < Merb::Rack::AbstractMiddleware
      # ==== Parameters
      # options<Hash>::
      #   Options for creating a new application. Currently ignored.
      def initialize(options={})
        @app = ::Rack::Builder.new {
           use Merb::Rack::PathPrefix, ::Merb::Config[:path_prefix]
           use Merb::Rack::Deferral 
           use Merb::Rack::Static, Merb.dir_for(:public)
           run Merb::Rack::MerbDispatch.new
         }.to_app
      end      
    end
  end  
end
