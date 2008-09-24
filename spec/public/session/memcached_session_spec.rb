$START_OPTIONS = { :session_store => "memcache" }

require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "session_spec")
require File.join(File.dirname(__FILE__), "controllers", "sessions")

require 'memcache'
Merb::MemcacheSession.store = MemCache.new('127.0.0.1:11211', { :namespace => 'my_app' })

begin
  Merb::MemcacheSession.store.stats  
rescue MemCache::MemCacheError
  puts "\nWarning: no connection to MemCache server at 127.0.0.1:11211 - some specs will fail!\n\n"
end

describe Merb::MemcacheSession do
  
  before do 
    @session_class = Merb::MemcacheSession
    @session = @session_class.generate
  end
  
  it_should_behave_like "All session-store backends"
  
  it "should have a session_store_type class attribute" do
    @session.class.session_store_type.should == :memcache
  end
  
end

describe Merb::MemcacheSession, "mixed into Merb::Controller" do
  
  before(:all) { @session_class = Merb::MemcacheSession }
  
  it_should_behave_like "All session-stores mixed into Merb::Controller"
  
end
