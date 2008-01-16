require 'memcache_util'

module Merb

  module SessionMixin #:nodoc:

    def setup_session
      Merb.logger.info("Setting up session")
      before = cookies[_session_id_key]
      request.session, cookies[_session_id_key] = Merb::MemCacheSession.persist(cookies[_session_id_key])
      @_fingerprint = Marshal.dump(request.session.data).hash
      @_new_cookie = cookies[_session_id_key] != before
    end

    def finalize_session
      Merb.logger.info("Finalize session")
      if @_fingerprint != Marshal.dump(request.session.data).hash
        ::Cache.put("session:#{@_session.session_id}", request.session.data)
      end
      set_cookie(_session_id_key, request.session.session_id, _session_expiry) if (@_new_cookie || request.session.needs_new_cookie)
    end

    def session_store_type
      "memcache"
    end
  end

  ##
  # Sessions stored in memcached.
  #
  # Requires setup in your +merb_init.rb+:
  #
  #   require 'memcache'
  #   CACHE = MemCache.new('127.0.0.1:11211', { :namespace => 'my_app' })
  #
  # And a setting in +merb.yml+:
  #
  #   :session_store: mem_cache

  class MemCacheSession

    attr_accessor :session_id
    attr_accessor :data
    attr_accessor :needs_new_cookie
    
    def initialize(session_id)
      @session_id = session_id
      @data = {}
    end

    class << self
      # Generates a new session ID and creates a row for the new session in the database.
      def generate
        sid = Merb::SessionMixin::rand_uuid
        new(sid)
      end

      # Gets the existing session based on the <tt>session_id</tt> available in cookies.
      # If none is found, generates a new session.
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

    # Regenerate the Session ID  
   	def regenerate 
   	  @session_id = Merb::SessionMixin::rand_uuid 
   	  self.needs_new_cookie=true 
   	end 
   	 
   	# Recreates the cookie with the default expiration time 
   	# Useful during log in for pushing back the expiration date 
   	def refresh_expiration 
   	  self.needs_new_cookie=true 
   	end 
   	
   	# Lazy-delete of session data 
   	def delete  
   	  @data = {} 
   	end

    # Has the session been loaded yet?
    def loaded?
      !! @data
    end
    
    # assigns a key value pair 
    def []=(k, v) 
      @data[k] = v
    end
    
    def [](k) 
      @data[k] 
    end 
     
    def each(&b) 
      @data.each(&b) 
    end
    
    private
    def method_missing(name, *args, &block)
      @data.send(name, *args, &block)
    end

  end

end
