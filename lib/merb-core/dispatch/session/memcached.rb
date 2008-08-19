module Merb

  module SessionMixin

    # Adds a before and after dispatch hook for setting up the memcached
    # session store.
    #
    # ==== Parameters
    # base<Class>:: The class to which the SessionMixin is mixed into.
    def setup_session
      # orig_sid = cookies[_session_id_key]
      # session = Merb::MemCacheSession.persist(orig_sid)
      # request.session = session
      # @_fingerprint = Marshal.dump(request.session).hash
      # if session.session_id != orig_sid 
      #   set_session_id_cookie(session.session_id)
      # end
      
      Merb::MemCacheSession.setup(request)
    end

    # Finalizes the session by storing the session ID in a cookie, if the
    # session has changed.
    def finalize_session
      if @_fingerprint != Marshal.dump(request.session).hash
        begin
          CACHE.set("session:#{request.session.session_id}", request.session)
        rescue => err
          Merb.logger.debug("MemCache Error: #{err.message}")
          Merb::SessionMixin::finalize_session_exception_callbacks.each {|x| x.call(err) }
        end
      end
      if request.session.needs_new_cookie or @_new_cookie
        set_session_id_cookie(request.session.session_id)
      end
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
  # Requires setup in your +init.rb+.
  #
  #   require 'memcached'
  #   CACHE = Memcached.new('127.0.0.1:11211', { :namespace => 'my_app' })
  #
  # And a setting in +init.rb+:
  #
  #   c[:session_store] = 'memcache'
  #
  # If you are using the memcached gem instead of memcache-client, you must setup like this:
  #
  #   require 'memcached'
  #   CACHE = Memcached.new('127.0.0.1:11211', { :namespace => 'my_app' })
  #
  class MemCacheSession < SessionStore

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
      # request<Merb::Request>:: The Merb::Request that came in from Rack.
      #
      # ==== Returns
      # SessionStore:: a SessionStore. If no sessions were found, 
      # a new SessionStore will be generated.
      def setup(request)
        session = retrieve(request.session_id)
        request.session = session
        @_fingerprint = Marshal.dump(request.session).hash
        set_session_id_cookie(session.session_id) if session.session_id != request.session_id
        session
      end
      
      # ==== Returns
      # String:: The session store type, i.e. "memory".
      def session_store_type
        "memcache"
      end
      
      private
      
      # ==== Parameters
      # session_id<String:: The ID of the session to retrieve.
      #
      # ==== Returns
      # Array::
      #   A pair consisting of a MemCacheSession and the session's ID. If no
      #   sessions matched session_id, a new MemCacheSession will be generated.
      #
      # ==== Notes
      # If there are persisted exceptions callbacks to execute, they all get executed
      # when Memcache library raises an exception.
      def retrieve(session_id)
        unless session_id.blank?
          begin
            session = CACHE.get("session:#{session_id}")
          rescue => err
            Merb.logger.warn!("Could not persist session to MemCache: #{err.message}")
            Merb::SessionMixin::persist_exception_callbacks.each {|x| x.call(err) }
          end
          if session.nil?
            # Not in memcached, but assume that cookie exists
            session = new(session_id)
          end
        else
          # No cookie...make a new session_id
          session = generate
        end
        if session.is_a?(MemCacheSession)
          session
        else
          # Recreate using the existing session as the data, when switching 
          # from another session type for example, eg. cookie to memcached
          session_object = MemCacheSession.new(session_id)
          session_object.update session
          session_object
        end
      end

    end

    # Regenerate the session ID.
    def regenerate
      @session_id = Merb::SessionMixin::rand_uuid
      self.needs_new_cookie=true
    end

  end

end
