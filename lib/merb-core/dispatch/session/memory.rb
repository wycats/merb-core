

# DOC: Ezra Zygmuntowicz FAILED
module Merb

  # DOC: Ezra Zygmuntowicz FAILED
  module SessionMixin #:nodoc:

    # DOC: Yehuda Katz FAILED
    def self.included(base)            
      base.add_hook :before_dispatch do
        Merb.logger.info("Setting up session")
        before = cookies[_session_id_key]
        request.session , cookies[_session_id_key] = Merb::MemorySession.persist(cookies[_session_id_key])
        @_new_cookie = cookies[_session_id_key] != before
      end
      
      base.add_hook :after_dispatch do
        Merb.logger.info("Finalize session")
        set_cookie(_session_id_key, request.session.session_id, _session_expiry) if (@_new_cookie || request.session.needs_new_cookie)
      end
    end

    # DOC: Ezra Zygmuntowicz FAILED
    def session_store_type
      "memory"
    end
  end
  
  ##
  # Sessions stored in memory.
  #
  # And a setting in +merb.yml+:
  #
  #   :session_store: mem_cache
  #   :memory_session_ttl: 3600 (in seconds, one hour)
  #
  # Sessions will remain in memory until the server is stopped or the time
  # as set in :memory_session_ttl expires.

  class MemorySession

    attr_accessor :session_id
    attr_accessor :data
    attr_accessor :needs_new_cookie

    # DOC: Ezra Zygmuntowicz FAILED
    def initialize(session_id)
      @session_id = session_id
      @data = {}
    end

    class << self
      # Generates a new session ID and creates a row for the new session in the database.

      # DOC: Ezra Zygmuntowicz FAILED
      def generate
        sid = Merb::SessionMixin::rand_uuid
        MemorySessionContainer[sid] = new(sid)
      end

      # Gets the existing session based on the <tt>session_id</tt> available in cookies.
      # If none is found, generates a new session.

      # DOC: Ezra Zygmuntowicz FAILED
      def persist(session_id)
        if session_id
          session = MemorySessionContainer[session_id]
        end
        unless session
          session = generate
        end
        [session, session.session_id]
      end

    end

    # Regenerate the Session ID

     # DOC
     def regenerate
       new_sid = Merb::SessionMixin::rand_uuid 
       old_sid = @session_id
       MemorySessionContainer[new_sid] = MemorySessionContainer[old_sid]
       @session_id = new_sid
       MemorySessionContainer.delete(old_sid)
       self.needs_new_cookie=true 
     end 
      
     # Recreates the cookie with the default expiration time 
     # Useful during log in for pushing back the expiration date

     # DOC
     def refresh_expiration 
       self.needs_new_cookie=true 
     end 
     
     # Lazy-delete of session data

     # DOC
     def delete
       @data = {} 
     end
     
    # Has the session been loaded yet?

    # DOC: Ezra Zygmuntowicz FAILED
    def loaded?
      !! @data
    end
    
    # assigns a key value pair

    # DOC: Ezra Zygmuntowicz FAILED
    def []=(k, v) 
      @data[k] = v
    end

    # DOC: Ezra Zygmuntowicz FAILED
    def [](k) 
      @data[k] 
    end

    # DOC: Ezra Zygmuntowicz FAILED
    def each(&b) 
      @data.each(&b) 
    end
    
    private

    # DOC: Ezra Zygmuntowicz FAILED
    def method_missing(name, *args, &block)
      @data.send(name, *args, &block)
    end

  end

  # DOC: Ezra Zygmuntowicz FAILED
  class MemorySessionContainer
    class << self

      # DOC: Ezra Zygmuntowicz FAILED
      def setup(ttl=nil)
        @sessions = Hash.new
        @timestamps = Hash.new
        @mutex = Mutex.new
        @session_ttl = ttl || 60*60 # default 1 hour
        start_timer
        self
      end

      # DOC: Ezra Zygmuntowicz FAILED
      def create(opts={})
        self[opts[:session_id]] = opts[:data]
      end

      # DOC: Ezra Zygmuntowicz FAILED
      def [](key)
        @mutex.synchronize {
          @timestamps[key] = Time.now
          @sessions[key]
        }
      end

      # DOC: Ezra Zygmuntowicz FAILED
      def []=(key, val) 
        @mutex.synchronize {
          @timestamps[key] = Time.now
          @sessions[key] = val
        } 
      end

      # DOC: Ezra Zygmuntowicz FAILED
      def delete(key)
        @mutex.synchronize {
          @sessions.delete(key)
          @timestamps.delete(key)
        }
      end

      # DOC: Ezra Zygmuntowicz FAILED
      def reap_old_sessions
        @timestamps.each do |key,stamp|
          if stamp + @session_ttl < Time.now
            delete(key)
          end  
        end
        GC.start
      end

      # DOC: Ezra Zygmuntowicz FAILED
      def start_timer
        Thread.new do
          loop {
            sleep @session_ttl
            reap_old_sessions
          } 
        end  
      end

      # DOC: Ezra Zygmuntowicz FAILED
      def sessions
        @sessions
      end  
      
    end # end singleton class

  end # end MemorySessionContainer
end

Merb::MemorySessionContainer.setup(Merb::Config[:memory_session_ttl])