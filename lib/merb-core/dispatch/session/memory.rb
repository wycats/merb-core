module Merb
  
  # Sessions stored in memory.
  #
  # Set it up by adding the following to your init file:
  #
  #  Merb::Config.use do |c|
  #    c[:session_store]      = :memory
  #    c[:memory_session_ttl] = 3600 # in seconds, one hour
  #  end
  #
  # Sessions will remain in memory until the server is stopped or the time
  # as set in :memory_session_ttl expires.
  class MemorySession < SessionStoreContainer
    
    # The session store type
    self.session_store_type = :memory
    
    # Bypass normal implicit class attribute reader - see below.
    def store
      self.class.store
    end
    
    # Lazy load/setup of MemorySessionStore.
    def self.store
      @_store ||= MemorySessionStore.new(Merb::Config[:memory_session_ttl])
    end
    
  end
  
  # Used for handling multiple sessions stored in memory.
  class MemorySessionStore
    
    # ==== Parameters
    # ttl<Fixnum>:: Session validity time in seconds. Defaults to 1 hour.
    def initialize(ttl=nil)
      @sessions = Hash.new
      @timestamps = Hash.new
      @mutex = Mutex.new
      @session_ttl = ttl || 60*60 # default 1 hour
      start_timer
    end
    
    # ==== Parameters
    # session_id<String>:: ID of the session to retrieve.
    #
    # ==== Returns
    # ContainerSession:: The session corresponding to the ID.
    def retrieve_session(session_id)
      @mutex.synchronize {
        @timestamps[session_id] = Time.now
        @sessions[session_id]
      }
    end

    # ==== Parameters
    # session_id<String>:: ID of the session to set.
    # data<ContainerSession>:: The session to set.
    def store_session(session_id, data)
      @mutex.synchronize {
        @timestamps[session_id] = Time.now
        @sessions[session_id] = data
      }
    end

    # ==== Parameters
    # session_id<String>:: ID of the session to delete.
    def delete_session(session_id)
      @mutex.synchronize {
        @timestamps.delete(session_id)
        @sessions.delete(session_id)
      }
    end

    # Deletes any sessions that have reached their maximum validity.
    def reap_old_sessions
      @timestamps.each do |session_id,stamp|
        delete_session(session_id) if (stamp + @session_ttl) < Time.now 
      end
      GC.start
    end

    # Starts the timer that will eventually reap outdated sessions.
    def start_timer
      Thread.new do
        loop {
          sleep @session_ttl
          reap_old_sessions
        } 
      end  
    end
    
  end

end