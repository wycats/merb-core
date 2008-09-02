module Merb
  
  class ContainerStore < SessionStore
    
    cattr_accessor :container
    attr_accessor  :_fingerprint
    
    # The class attribute :container holds a reference to an object that implements 
    # the following interface (either as class or instance methods): 
    #
    # - retrieve_session(session_id) (returns data as Hash, Mash or SessionStore)
    # - store_session(session_id, data)
    # - delete_session(session_id)
    #
    # Example:
    #
    # ActiveRecordSession < ContainerStore
    #
    # ActiveRecordSessionModel < ::ActiveRecord::Base
    #
    # self.container = ActiveRecordSessionModel
    #
    # ActiveRecordSessionModel.retrieve_session(session_id)
    # ActiveRecordSessionModel.store_session(session_id, data)
    # ActiveRecordSessionModel.delete_session(session_id)
    
    class << self

      # Generates a new session ID and creates a new session.
      #
      # ==== Returns
      # ContainerStore:: The new session.
      def generate
        session = new(Merb::SessionMixin.rand_uuid)
        session.needs_new_cookie = true
        session
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
        # TODO Marshal.dump is slow - needs optimization
        session._fingerprint = Marshal.dump(request.session).hash
        session
      end
            
      private
      
      # ==== Parameters
      # session_id<String:: The ID of the session to retrieve.
      #
      # ==== Returns
      # ContainerStore:: ContainerStore instance with the session data. If no
      #   sessions matched session_id, a new ContainerStore will be generated.
      #
      # ==== Notes
      # If there are persisted exceptions callbacks to execute, they all get executed
      # when Memcache library raises an exception.
      def retrieve(session_id)
        unless session_id.blank?
          begin
            session_data = container.retrieve_session(session_id)
          rescue => err
            Merb.logger.warn!("Could not retrieve session from #{self.name}: #{err.message}")
          end
          # Not in container, but assume that cookie exists
          session_data = new(session_id) if session_data.nil?
        else
          # No cookie...make a new session_id
          session_data = generate
        end
        if session_data.is_a?(self)
          session_data
        else
          # Recreate using the existing session as the data, when switching 
          # from another session type for example, eg. cookie to memcached
          # or when the data is just a hash
          new(session_id).update(session_data)
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
          container.store_session(request.session(self.class.session_store_type).session_id, self)
        rescue => err
          Merb.logger.warn!("Could not persist session to #{self.class.name}: #{err.message}")
        end
      end
      if needs_new_cookie || Merb::SessionMixin.needs_new_cookie
        request.set_session_id_cookie(session_id)
      end
    end

    # Regenerate the session ID.
    def regenerate
      self.session_id = Merb::SessionMixin.rand_uuid
    end
    
  end
end