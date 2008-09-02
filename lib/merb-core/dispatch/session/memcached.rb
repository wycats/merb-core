module Merb

  # Sessions stored in memcached.
  #
  # Requires setup in your +init.rb+.
  #
  #   require 'memcached'
  #   Merb::MemcacheSession.cache = Memcached.new('127.0.0.1:11211', { :namespace => 'my_app' })
  #
  # And a setting in +init.rb+:
  #
  #   c[:session_store] = 'memcache'
  #
  # If you are using the memcached gem instead of memcache-client, you must setup like this:
  #
  #   require 'memcached'
  #   Merb::MemcacheSession.cache = Memcached.new('127.0.0.1:11211', { :namespace => 'my_app' })  
  
  class MemcacheSession < ContainerStore
    class << self
      
      # ==== Parameters
      # memcache<Memcached>:: A Memcached instance that has been setup.
      #
      # Note: this is an alias for ContainerStore.container
      def cache=(memcache)
        self.container = memcache
      end
      
      # ==== Returns
      # Symbol:: The session store type, i.e. :memory.
      def session_store_type
        :memcache
      end

    end
  end

end

class Memcached
  
  # Make Memcached conform to the ContainerStore interface
  
  def retrieve_session(session_id)
    get("session:#{session_id}")
  end
  
  def store_session(session_id, data)
    set("session:#{session_id}", data)
  end
  
end