module Merb
  
  module SessionMixin
    # Sets the session id cookie, along with the correct
    # expiry and domain -- used for new or reset sessions
    def set_session_id_cookie(key)
      options = {}
      options[:value] = key
      options[:expires] = Time.now + _session_expiry if _session_expiry > 0
      options[:domain] = _session_cookie_domain if _session_cookie_domain
      cookies[_session_id_key] = options
    end

    @_finalize_session_exception_callbacks = []
    @_persist_exception_callbacks = []
    
    # ==== Returns
    # String:: A random 32 character string for use as a unique session ID.
    def rand_uuid
      values = [
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x1000000),
        rand(0x1000000),
      ]
      "%04x%04x%04x%04x%04x%06x%06x" % values
    end

    # Marks this session as needing a new cookie.
    def needs_new_cookie!
      @_new_cookie = true
    end
    
    def finalize_session_exception_callbacks(&block)
      if block_given?
        @_finalize_session_exception_callbacks << block
      else
        @_finalize_session_exception_callbacks
      end
    end
    
    def persist_exception_callbacks(&block)
      if block_given?
        @_persist_exception_callbacks << block
      else
        @_persist_exception_callbacks
      end
    end
    
    module_function :rand_uuid, :needs_new_cookie!, :finalize_session_exception_callbacks, :persist_exception_callbacks
  end

end
