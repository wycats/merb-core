require 'memcache_util'
module Merb

  module SessionMixin #:nodoc:

    # Adds a before and after dispatch hook for setting up the memcached
    # session store.
    #
    # ==== Parameters
    # base<Class>:: The class to which the SessionMixin is mixed into.
    def setup_session
      before = cookies[_session_id_key]
      request.session, cookies[_session_id_key] = Merb::MemCacheSession.persist(cookies[_session_id_key])
      @_fingerprint = Marshal.dump(request.session.data).hash
      @_new_cookie = cookies[_session_id_key] != before
    end

    # Finalizes the session by storing the session ID in a cookie, if the
    # session has changed.
    def finalize_session 
      if @_fingerprint != Marshal.dump(request.session.data).hash
        ::Cache.put("session:#{request.session.session_id}", request.session.data)
      end
      set_cookie(_session_id_key, request.session.session_id, Time.now + _session_expiry) if (@_new_cookie || request.session.needs_new_cookie)
    end

    # ==== Returns
    # String:: The session store type, i.e. "memcache".
    def session_store_type
      "memcache"
    end
  end

  ##
  # Sessions stored in memcached.
  #
  # Requires setup in your +init.rb+:
  #
  #   require 'memcache'
  #   CACHE = MemCache.new('127.0.0.1:11211', { :namespace => 'my_app' })
  #
  # And a setting in +init.rb+:
  #
  #   c[:session_store] = 'memcache'
  class MemCacheSession

    attr_accessor :session_id
    attr_accessor :data
    attr_accessor :needs_new_cookie

    # ==== Parameters
    # session_id<String>:: A unique identifier for this session.
    def initialize(session_id)
      @session_id = session_id
      @data = {}
    end

    class << self

      # Generates a new session ID and creates a new session.
      #
      # ==== Returns
      # MemCacheSession:: The new session.
      def generate
        sid = Merb::SessionMixin::rand_uuid
        new(sid)
      end

      # ==== Parameters
      # session_id<String:: The ID of the session to retrieve.
      #
      # ==== Returns
      # Array::
      #   A pair consisting of a MemCacheSession and the session's ID. If no
      #   sessions matched session_id, a new MemCacheSession will be generated.
      def persist(session_id)
        unless session_id.blank?
          session = ::Cache.get("session:#{session_id}")
          if session.nil?
            # Not in memcached, but assume that cookie exists
            session = new(session_id)
          end
        else
          # No cookie...make a new session_id
          session = generate
        end
        if session.is_a?(MemCacheSession)
          [session, session.session_id]
        else
          # recreate using the rails session as the data
          session_object = MemCacheSession.new(session_id)
          session_object.data = session
          [session_object, session_object.session_id]
        end

      end

      # Don't try to reload in dev mode.
      def reloadable? #:nodoc:
        false
      end

    end

    # Regenerate the session ID.
    def regenerate 
      @session_id = Merb::SessionMixin::rand_uuid 
      self.needs_new_cookie=true 
    end 
      
    # Recreates the cookie with the default expiration time. Useful during log
    # in for pushing back the expiration date.
    def refresh_expiration 
      self.needs_new_cookie=true 
    end 
     
    # Deletes the session by emptying stored data.
    def delete  
      @data = {} 
    end

    # ==== Returns
    # Boolean:: True if session has been loaded already.
    def loaded?
      !! @data
    end
    
    # ==== Parameters
    # k<~to_s>:: The key of the session parameter to set.
    # v<~to_s>:: The value of the session parameter to set.
    def []=(k, v) 
      @data[k] = v
    end

    # ==== Parameters
    # k<~to_s>:: The key of the session parameter to retrieve.
    #
    # ==== Returns
    # String:: The value of the session parameter.
    def [](k) 
      @data[k] 
    end

    # Yields the session data to an each block.
    #
    # ==== Parameter
    # &b:: The block to pass to each.
    def each(&b) 
      @data.each(&b) 
    end
    
    private

    # Attempts to redirect any messages to the data object.
    def method_missing(name, *args, &block)
      @data.send(name, *args, &block)
    end

  end

end