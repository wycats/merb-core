require 'rack'
module Merb
  module Rack
    autoload :Adapter,      "merb-core/rack/adapter"
    autoload :FastCGI,      "merb-core/rack/adapter/fcgi"
    autoload :Irb,          "merb-core/rack/adapter/irb"
    autoload :Mongrel,      "merb-core/rack/adapter/mongrel"
    autoload :Thin,         "merb-core/rack/adapter/thin"
    autoload :WEBrick,      "merb-core/rack/adapter/webrick"

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