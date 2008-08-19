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
  
  end
  
end
