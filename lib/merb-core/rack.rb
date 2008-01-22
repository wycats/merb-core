require 'rack'
module Merb
  module Rack
    autoload :Application,    "merb-core/rack/application"
    autoload :Adapter,        "merb-core/rack/adapter"
    autoload :EventedMongrel, "merb-core/rack/adapter/evented_mongrel"    
    autoload :FastCGI,        "merb-core/rack/adapter/fcgi"
    autoload :IRB,            "merb-core/rack/adapter/irb"
    autoload :Mongrel,        "merb-core/rack/adapter/mongrel"
    autoload :Runner,         "merb-core/rack/adapter/runner"    
    autoload :Thin,           "merb-core/rack/adapter/thin"
    autoload :WEBrick,        "merb-core/rack/adapter/webrick"
    
    class RequestWrapper
      def initialize(env)
        @env = env
      end
      
      def params
        @env
      end
      
      def body
        @env['rack.input']
      end
    end

  end # Rack
end # Merb