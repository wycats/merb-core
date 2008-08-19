require 'merb-core/dispatch/session/store'

module Merb
  
  module SessionMixin
    
    def self.included(base)
      base.class_inheritable_accessor :_session_id_key, :_session_secret_key, 
                                      :_session_expiry, :_session_cookie_domain
      
      base._session_secret_key = nil
      base._session_id_key = Merb::Config[:session_id_key] || '_session_id'
      base._session_expiry = Merb::Config[:session_expiry] || Merb::Const::WEEK * 2
      base._session_cookie_domain = Merb::Config[:session_cookie_domain]
      
      base._before_dispatch_callbacks << lambda { |c| c.setup_session }
      base._after_dispatch_callbacks  << lambda { |c| c.finalize_session }
    end
    
    # ==== Returns
    # Hash:: The session that was extracted from the request object.
    def session() request.session end
    
    # Method stub for setting up the session. This will be overriden by session
    # modules.
    def setup_session()    end

    # Method stub for finalizing up the session. This will be overriden by
    # session modules.
    def finalize_session() end

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
    
    module_function :rand_uuid, :needs_new_cookie!, :finalize_session_exception_callbacks, :persist_exception_callbacks
  end

end
