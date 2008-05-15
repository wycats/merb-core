module Merb
  module Rack
    class Static < Merb::Rack::Middleware

      def initialize(app,directory)
        super(app)
        @static_server = ::Rack::File.new(directory)
      end
      
      def call(env)        
        path = env['PATH_INFO'] ? env['PATH_INFO'].chomp('/') : ""
        cached_path = (path.empty? ? 'index' : path) + '.html'
        
        if file_exist?(path) && env['REQUEST_METHOD'] =~ /GET|HEAD/ # Serve the file if it's there and the request method is GET or HEAD
          serve_static(env)
        elsif file_exist?(cached_path) && env['REQUEST_METHOD'] =~ /GET|HEAD/ # Serve the page cache if it's there and the request method is GET or HEAD
          env['PATH_INFO'] = cached_path
          serve_static(env)
        elsif path =~ /favicon\.ico/
          return [404, {"Content-Type"=>"text/html"}, "404 Not Found."]
        else
          @app.call(env)
        end
      end
      
       # ==== Parameters
        # path<String>:: The path to the file relative to the server root.
        #
        # ==== Returns
        # Boolean:: True if file exists under the server root and is readable.
        def file_exist?(path)
          full_path = ::File.join(@static_server.root, ::Merb::Request.unescape(path))
          ::File.file?(full_path) && ::File.readable?(full_path)
        end

        # ==== Parameters
        # env<Hash>:: Environment variables to pass on to the server.
        def serve_static(env)
          env["PATH_INFO"] = ::Merb::Request.unescape(env["PATH_INFO"])        
          @static_server.call(env)
        end
      
    end
  end
end