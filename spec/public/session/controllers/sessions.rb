module Merb::Test::Fixtures
  
  module Controllers

    class Testing < Merb::Controller
      self._template_root = File.dirname(__FILE__) / "views"
    end

    class SessionsController < Testing
    
      def index
        request.session[:foo] = params[:foo]
        Merb::Config[:session_store]
      end
      
      def retrieve
      end
    
    end
    
    class MultipleSessionsController < Testing
    
      def store_in_cookie
        request.session(:cookie)[:foo] = params[:foo]
      end
      
      def store_in_memory
        request.session(:memory)[:foo] = params[:foo]
      end
      
      def store_in_memcache
        request.session(:memcache)[:foo] = params[:foo]
      end
      
      def store_in_multiple
        request.session(:memcache)[:foo] = 'memcache-baz'
        request.session(:memory)[:foo] = 'memory-baz'
        request.session(:cookie)[:foo] = 'cookie-baz'
      end
      
      def retrieve
      end
      
    end
  
  end
  
end
