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
    # session_id<String:: The ID of the session to retrieve.
    #
    # ==== Returns
    # Array::
    #   A pair consisting of a SessionStore and the session's ID. If no
    #   sessions matched session_id, a new SessionStore will be generated.
    def persist(session_id)
    end
    
    # ==== Returns
    # String:: The session store type, i.e. "memory".
    def session_store_type; ""; end
    
  end
  
  # ==== Parameters
  # session_id<String>:: A unique identifier for this session.
  def initialize(session_id)
    @session_id = session_id
  end
  
  # Regenerate the Session ID
  def regenerate
    refresh_expiration
  end
  
  # Recreates the cookie with the default expiration time. Useful during log
  # in for pushing back the expiration date.
  def refresh_expiration 
    self.needs_new_cookie=true 
  end
  
end