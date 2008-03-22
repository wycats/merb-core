module Merb
  
  module Rack

    class Application
      # ==== Parameters
      # options<Hash>::
      #   Options for creating a new application. Currently ignored.
      def initialize(options={})
        @static_server = ::Rack::File.new Merb.dir_for(:public)
        if prefix = ::Merb::Config[:path_prefix]
          @path_prefix = /^#{Regexp.escape(prefix)}/
        end
      end

      # ==== Parameters
      # env<Hash>:: Environment variables to pass on to the application.
      #
      # ==== Returns
      # Array[Array]::
      #   A 3 element tuple consisting of response status, headers and body.
      def call(env) 
        strip_path_prefix(env) if @path_prefix  # Strip out the path_prefix if one was set 
        path = env['PATH_INFO'] ? env['PATH_INFO'].chomp('/') : ""
        cached_path = (path.empty? ? 'index' : path) + '.html'
        Merb.logger.info "Request: #{path}"
        if file_exist?(path) && env['REQUEST_METHOD'] =~ /GET|HEAD/ # Serve the file if it's there and the request method is GET or HEAD
          serve_static(env)
        elsif file_exist?(cached_path) && env['REQUEST_METHOD'] =~ /GET|HEAD/ # Serve the page cache if it's there and the request method is GET or HEAD
          env['PATH_INFO'] = cached_path
          serve_static(env)
        else                              # No static file, let Merb handle it
          if path =~ /favicon\.ico/
            return [404, {"Content-Type"=>"text/html"}, "404 Not Found."]
          end  
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
      
      # ==== Parameters
      # env<Hash>:: Environment variables to pass on to the server.
      def strip_path_prefix(env)
        ['PATH_INFO', 'REQUEST_URI'].each do |path_key|
          if env[path_key] =~ @path_prefix
            env[path_key].sub!(@path_prefix, '')
            env[path_key] = '/' if env[path_key].empty?
          end
        end
      end
      
    end
  end  
end    