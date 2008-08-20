module Merb
  class SessionStore < Hash
  
    attr_accessor :session_id
    attr_accessor :needs_new_cookie
  
    class << self
  
      # Generates a new session ID and creates a new session.
      #
      # ==== Returns
      # SessionStore:: The new session.
      def generate
      end
    
      # ==== Parameters
      # request<Merb::Request>:: The Merb::Request that came in from Rack.
      #
      # ==== Returns
      # SessionStore:: a SessionStore. If no sessions were found, 
      # a new SessionStore will be generated.
      def setup(request)
      end    
    
      # ==== Returns
      # Symbol:: The session store type, i.e. :memory.
      def session_store_type() end
    
    end
  
    # ==== Parameters
    # session_id<String>:: A unique identifier for this session.
    def initialize(session_id)
      @session_id = session_id
    end
  
    # Teardown and/or persist the current session.
    #
    # ==== Parameters
    # request<Merb::Request>:: The Merb::Request that came in from Rack.
    def finalize(request)
    end
  
    # Regenerate the Session ID
    def regenerate
      refresh_expiration
    end
  
    # Recreates the cookie with the default expiration time. Useful during log
    # in for pushing back the expiration date.
    def refresh_expiration 
      self.needs_new_cookie = true 
    end
  
  end
end