module Merb

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
  class MemcacheSession < SessionStore

    attr_accessor :_fingerprint

    class << self

      # Generates a new session ID and creates a new session.
      #
      # ==== Returns
      # MemcacheSession:: The new session.
      def generate
        new(Merb::SessionMixin::rand_uuid)
      end

      # Setup a new session.
      #
      # ==== Parameters
      # request<Merb::Request>:: The Merb::Request that came in from Rack.
      #
      # ==== Returns
      # SessionStore:: a SessionStore. If no sessions were found, 
      # a new SessionStore will be generated.
      def setup(request)
        session = retrieve(request.session_id)
        request.session = session
        session._fingerprint = Marshal.dump(request.session).hash
        set_session_id_cookie(session.session_id) if session.session_id != request.session_id
        session
      end
      
      # ==== Returns
      # Symbol:: The session store type, i.e. :memory.
      def session_store_type
        :memcache
      end
      
      private
      
      # ==== Parameters
      # session_id<String:: The ID of the session to retrieve.
      #
      # ==== Returns
      # Array::
      #   A pair consisting of a MemcacheSession and the session's ID. If no
      #   sessions matched session_id, a new MemcacheSession will be generated.
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
          end
          if session.nil?
            # Not in memcached, but assume that cookie exists
            session = new(session_id)
          end
        else
          # No cookie...make a new session_id
          session = generate
        end
        if session.is_a?(MemcacheSession)
          session
        else
          # Recreate using the existing session as the data, when switching 
          # from another session type for example, eg. cookie to memcached
          session_object = MemcacheSession.new(session_id)
          session_object.update session
          session_object
        end
      end

    end
    
    # Teardown and/or persist the current session.
    #
    # ==== Parameters
    # request<Merb::Request>:: The Merb::Request that came in from Rack.
    def finalize(request)
      if _fingerprint != Marshal.dump(self).hash
        begin
          CACHE.set("session:#{request.session.session_id}", self)
        rescue => err
          Merb.logger.debug("MemCache Error: #{err.message}")
        end
      end
      if needs_new_cookie || Merb::SessionMixin.needs_new_cookie
        request.set_session_id_cookie(session_id)
      end
    end

    # Regenerate the session ID.
    def regenerate
      self.session_id = Merb::SessionMixin::rand_uuid
      refresh_expiration
    end

  end

end
