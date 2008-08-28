module Merb
  module Rack

    class ConditionalGet < Merb::Rack::Middleware
      def call(env)
        status, headers, body = @app.call(env)

        # set Date header using RFC1123 date format as specified by HTTP
        # RFC2616 section 3.3.1.
        if etag = headers['ETag']
          status = 304 if etag == env[Merb::Const::HTTP_IF_NONE_MATCH]
        end

        if last_modified = headers[Merb::Const::LAST_MODIFIED]
          status = 304 if last_modified == env[Merb::Const::HTTP_IF_MODIFIED_SINCE]
        end

        if status == 304
          body = ""
        end
        
        [status, headers, body]
      end
    end
    
  end
end
