require 'merb-core/dispatch/session/store'

module Merb
  
  module SessionMixin
    
    module RequestMixin
      
      def self.included(base)
        base.class_inheritable_accessor :_session_id_key, :_session_secret_key, 
                                        :_session_expiry, :_default_cookie_domain

        base._session_id_key        = Merb::Config[:session_id_key] || '_session_id'
        base._session_expiry        = Merb::Config[:session_expiry] || Merb::Const::WEEK * 2
        base._session_secret_key    = Merb::Config[:session_secret_key]
        base._default_cookie_domain = Merb::Config[:default_cookie_domain]
      end
      
      # The default session store type.
      def default_session_store
        Merb::Config[:session_store] ? Merb::Config[:session_store].to_sym : nil
      end
      
      # ==== Returns
      # Hash:: All active session stores by type.
      def session_stores
        @session_stores ||= {}
      end
      
      # ==== Parameters
      # session_store<String>:: The type of session store to access, 
      # defaults to default_session_store.
      #
      # === Notes
      # If no suitable session store type is given, it defaults to
      # cookie-based sessions.
      def session(session_store = nil)
        session_store ||= default_session_store
        if Merb.registered_session_types[session_store]
          session_stores[session_store] ||= begin
            session_store_class = Merb.const_get(Merb.registered_session_types[session_store][:class])
            session_store_class.setup(self)
          end
        else
          Merb.logger.warn "Session store not found, '#{session_store}'."
          Merb.logger.warn "Defaulting to CookieStore Sessions"
          session(:cookie)
        end
      end
      
      # ==== Parameters
      # new_session<Merb::SessionStore>:: A session store instance.
      #
      # === Notes
      # The session is assigned internally by its session_store_type key.
      def session=(new_session)
        session_stores[new_session.class.session_store_type] = new_session
      end
      
      # Whether a session has been setup
      def session?(session_store = nil)
        if session_store
          session_stores[session_store].is_a?(Merb::SessionStore)
        else
          session_stores.any? { |type, store| store.is_a?(Merb::SessionStore) }
        end
      end
      
      # SESSIONTODO how to differentiate between different session stores in one active app?
      
      # Teardown and/or persist the current session.
      def finalize_session
        session.finalize(self) if session?
      end
      
      # Assign default cookie values
      def set_default_cookies
        if route && route.allow_fixation? && params.key?(_session_id_key)
          Merb.logger.info("Fixated session id: #{_session_id_key}")
          cookies[_session_id_key] = params[_session_id_key]
        end
      end
      
      # ==== Parameters
      # value<String>:: The value of the session cookie; either the session id or the actual encoded data.
      def set_session_cookie_value(value)
        options = {}
        options[:value]   = value
        options[:expires] = Time.now + (_session_expiry || Merb::Const::WEEK * 2)
        options[:domain]  = _default_cookie_domain
        cookies[_session_id_key] = options
      end
      alias :set_session_id_cookie :set_session_cookie_value
      
      # ==== Returns
      # String:: The value of the session cookie; either the session id or the actual encoded data.
      def session_cookie_value
        cookies[_session_id_key]
      end
      alias :session_id :session_cookie_value

    end
    
    def self.included(base)
      base.class_inheritable_accessor :_default_cookie_domain
      base._default_cookie_domain = Merb::Config[:default_cookie_domain]
      
      base._after_dispatch_callbacks << lambda { |c| c.finalize_session }
    end
    
    # ==== Parameters
    # session_store<String>:: The type of session store to access.
    #
    # ==== Returns
    # Hash:: The session that was extracted from the request object.
    def session(session_store = nil) request.session(session_store) end
    
    # SESSIONTODO
    def finalize_session
      request.finalize_session
    end  
      
    # Module methods

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
    
    def needs_new_cookie
      @_new_cookie
    end

    # Adds a callback to the list of callbacks run when
    # exception is raised on session finalization, so
    # you can recover.
    #
    # See session mixins documentation for details on
    # session finalization.
    #
    # ==== Params
    # &block::
    #   A block to be added to the callbacks that will be executed
    #   if there's exception on session finalization.
    def finalize_session_exception_callbacks(&block)
      if block_given?
        @_finalize_session_exception_callbacks << block
      else
        @_finalize_session_exception_callbacks
      end
    end

    # Adds a callback to the list of callbacks run when
    # exception is raised on session persisting, so
    # you can recover.
    #
    # See session mixins documentation for details on
    # session persisting.
    #
    # ==== Params
    # &block::
    #   A block to be added to the callbacks that will be executed
    #   if there's exception on session persisting.
    def persist_exception_callbacks(&block)
      if block_given?
        @_persist_exception_callbacks << block
      else
        @_persist_exception_callbacks
      end
    end
    
    module_function :rand_uuid, :needs_new_cookie, :needs_new_cookie!, 
      :finalize_session_exception_callbacks, :persist_exception_callbacks
  end

end
