

module Merb
  
  module Rack

    class Application

      def initialize(options={})
        @static_server = ::Rack::File.new(::File.join(Merb.root, "public"))
      end

      def call(env)
        path        = env['PATH_INFO'].chomp('/')
        cached_path = (path.empty? ? 'index' : path) + '.html'
        
        if file_exist?(path)              # Serve the file if it's there
          serve_static(env)
        elsif file_exist?(cached_path)    # Serve the page cache if it's there
          env['PATH_INFO'] = cached_path
          serve_static(env)
        else                              # No static file, let Merb handle it
          begin
            controller = ::Merb::Dispatcher.handle(env, ::Rack::Response.new)
          rescue Object => e
            return [500, {"Content-Type"=>"text/html"}, e.message + "<br/>" + e.backtrace.join("<br/>")]
          end
          Merb.logger.flush
          [controller.status, controller.headers, controller.body]
        end
      end
      
      # TODO refactor this in File#can_serve?(path) ??

      def file_exist?(path)
        full_path = ::File.join(@static_server.root, ::Rack::Utils.unescape(path))
        ::File.file?(full_path) && ::File.readable?(full_path)
      end

      def serve_static(env)
        @static_server.call(env)
      end
      
    end
  end  
end    