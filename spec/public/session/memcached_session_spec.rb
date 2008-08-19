$START_OPTIONS = { :session_store => "memcache" }

require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "session_spec")
require File.join(File.dirname(__FILE__), "controllers", "sessions")

require 'memcached'
CACHE = Memcached.new('127.0.0.1:11211', { :namespace => 'my_app' })

require "merb-core/dispatch/session/memcached"

describe Merb::MemCacheSession do
  
  before do 
    @session_class = Merb::MemCacheSession
    @session = @session_class.generate
  end
  
  it_should_behave_like "All session-store backends"
  
end

describe Merb::MemCacheSession, "mixed into Merb::Controller" do
  
  before(:all) do
    @session_class = Merb::MemCacheSession
    @session = @session_class.generate
  end
  
  it_should_behave_like "All session-stores mixed into Merb::Controller"
  
end