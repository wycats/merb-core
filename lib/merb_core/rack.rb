require 'rack'
module Merb
  module Rack
    autoload :Adapter,      "merb_core/rack/adapter"
    autoload :Mongrel,      "merb_core/rack/adapter/mongrel"
    autoload :Thin,         "merb_core/rack/adapter/thin"
    autoload :WEBrick,      "merb_core/rack/adapter/webrick"
    autoload :FastCGI,      "merb_core/rack/adapter/fcgi"
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
    
    class << self
        
      def start(host, ports)
        ports.each do |port|
          start_server(host, port)
          trap("INT"){ Merb.stop }
        end  
      end
      
      def stop  
      end
      
    end # class << self
    
  end # Rack
end # Merb