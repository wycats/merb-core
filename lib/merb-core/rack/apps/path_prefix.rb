module Merb
  module Rack
    class PathPrefix < Merb::Rack::Middleware

      def initialize(app, path_prefix = nil)
        super(app)
        @path_prefix = /^#{Regexp.escape(path_prefix)}/
      end
      
      def deferred?(env)
        strip_path_prefix(env) 
        @app.deferred?(env)
      end
      
      def call(env)
        strip_path_prefix(env) 
        @app.call(env)
      end

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