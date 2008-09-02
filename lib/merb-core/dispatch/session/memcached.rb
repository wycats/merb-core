module Merb

  # Sessions stored in memcached.
  #
  # Requires setup in your +init.rb+.
  #
  #   require 'memcached'
  #   Merb::MemcacheSession.container = Memcached.new('127.0.0.1:11211', { :namespace => 'my_app' })
  #
  # And a setting in +init.rb+:
  #
  #   c[:session_store] = 'memcache'
  #
  # If you are using the memcached gem instead of memcache-client, you must setup like this:
  #
  #   require 'memcached'
  #   Merb::MemcacheSession.container = Memcached.new('127.0.0.1:11211', { :namespace => 'my_app' })  
  
  class MemcacheSession < ContainerStore
    
    # The session store type
    self.session_store_type = :memcache
    
  end

end

class Memcached
  
  # Make Memcached conform to the ContainerStore interface
  
  # ==== Parameters
  # session_id<String>:: ID of the session to retrieve.
  #
  # ==== Returns
  # ContainerSession:: The session corresponding to the ID.
  def retrieve_session(session_id)
    get("session:#{session_id}")
  end
  
  # ==== Parameters
  # session_id<String>:: ID of the session to set.
  # data<ContainerSession>:: The session to set.
  def store_session(session_id, data)
    set("session:#{session_id}", data)
  end
  
  # ==== Parameters
  # session_id<String>:: ID of the session to delete.
  def delete_session(session_id)
    delete("session:#{session_id}")
  end
  
end