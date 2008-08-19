class SessionStore < Hash
  
  attr_accessor :session_id
  attr_accessor :needs_new_cookie
  
  # ==== Parameters
  # session_id<String>:: A unique identifier for this session.
  def initialize(session_id)
    @session_id = session_id
  end
  
  class << self
  
    def generate
    end
  
    def persist(session_id)
    end
    
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