# for OSX compatibility
Socket.do_not_reverse_lookup = true

module Merb
  module Rack

    class Adapter
      def initialize(options={})
        @static_server = ::Rack::File.new(::File.join(Merb.root, "public"))
      end
      
      
      def call(env)
        path        = env['PATH_INFO'].chomp('/')
        cached_path = (path.empty? ? 'index' : path) + '.html'
        
        if file_exist?(path)              # Serve the file if it's there
          serve_staic(env)
        elsif file_exist?(cached_path)    # Serve the page cache if it's there
          env['PATH_INFO'] = cached_path
          serve_staic(env)
        else                              # No static file, let Merb handle it
          serve_dynamic(env)
        end
      end
      
      # TODO refactor this in File#can_serve?(path) ??
      def file_exist?(path)
        full_path = ::File.join(@static_server.root, ::Rack::Utils.unescape(path))
        ::File.file?(full_path) && ::File.readable?(full_path)
      end
      
      def serve_staic(env)
        @static_server.call(env)
      end
      
      def serve_dynamic(env)
        request = RequestWrapper.new(env)
        response = StringIO.new
        begin
          controller, action = ::Merb::Dispatcher.handle(request, response)
        rescue Object => e
          return [500, {"Content-Type"=>"text/html"}, "Internal Server Error"]
        end
        [controller.status, controller.headers, controller.body]
      end

      
    end
  end  
end    