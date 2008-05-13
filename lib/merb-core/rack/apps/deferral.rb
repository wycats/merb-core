module Merb
  module Rack
    class Deferral < Merb::Rack::AbstractMiddleware
      
     def deferred?(env)
       path = env['PATH_INFO'] ? env['PATH_INFO'].chomp('/') : ""
       if path =~ Merb.deferred_actions
         Merb.logger.info! "Deferring Request: #{path}"
         true
       else
         false
       end
     end
     
    end
  end
end