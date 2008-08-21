$START_OPTIONS = { :session_stores => ["cookie", "memory", "memcache"], :session_secret_key => "session-secret-key-here" }

require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "session_spec")
require File.join(File.dirname(__FILE__), "controllers", "sessions")

require 'memcached'
Merb::MemcacheSession.cache = Memcached.new('127.0.0.1:11211', { :namespace => 'my_app' })

describe "An app with multiple session stores configured" do
  
  it "should have each store type listed in Merb::Request.registered_session_types" do
    Merb::Request.registered_session_types[:cookie].should == "Merb::CookieSession"
    Merb::Request.registered_session_types[:memory].should == "Merb::MemorySession"
    Merb::Request.registered_session_types[:memcache].should == "Merb::MemcacheSession"
  end
  
  it "should allow you to use cookie-based sessions" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::MultipleSessionsController, :store_in_cookie, :foo => "cookie-bar")
    controller.request.session(:cookie)[:foo].should == "cookie-bar"
    controller.request.session[:foo].should == "cookie-bar" # defaults to the first registered store
    
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::MultipleSessionsController, :retrieve, {}, 
      Merb::Const::HTTP_COOKIE => "#{Merb::Request._session_id_key}=#{controller.session(:cookie).to_cookie}")
    controller.request.session(:cookie)[:foo].should == "cookie-bar"
    controller.request.session[:foo].should == "cookie-bar" # defaults to the first registered store
  end
  
  it "should allow you to use memory-based sessions" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::MultipleSessionsController, :store_in_memory, :foo => "memory-bar")
    controller.request.session(:memory)[:foo].should == "memory-bar"
    sid = controller.request.session(:memory).session_id
    
    controller = dispatch_with_session_to(Merb::Test::Fixtures::Controllers::MultipleSessionsController, :retrieve, sid)    
    controller.request.session(:memory)[:foo].should == "memory-bar"
  end
  
  it "should allow you to use memcache-based sessions" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::MultipleSessionsController, :store_in_memcache, :foo => "memcache-bar")
    controller.request.session(:memcache)[:foo].should == "memcache-bar"
    sid = controller.request.session(:memcache).session_id
    
    controller = dispatch_with_session_to(Merb::Test::Fixtures::Controllers::MultipleSessionsController, :retrieve, sid)
    controller.request.session(:memcache)[:foo].should == "memcache-bar"    
  end
  
  it "should allow you to use them simultaneously" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::MultipleSessionsController, :store_in_multiple)
    controller.request.session(:cookie)[:foo].should == "cookie-baz"
    
    memory_sid = controller.request.session(:memory).session_id
    memcache_sid = controller.request.session(:memcache).session_id
    
    # memory_sid.should == memcache_sid # TODO
    
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::MultipleSessionsController, :retrieve, {}, 
      Merb::Const::HTTP_COOKIE => "#{Merb::Request._session_id_key}=#{controller.session(:cookie).to_cookie}")
    controller.request.session(:cookie)[:foo].should =="cookie-baz"
    
    controller = dispatch_with_session_to(Merb::Test::Fixtures::Controllers::MultipleSessionsController, :retrieve, memory_sid)    
    controller.request.session(:memory)[:foo].should == "memory-baz"
    
    controller = dispatch_with_session_to(Merb::Test::Fixtures::Controllers::MultipleSessionsController, :retrieve, memcache_sid)    
    controller.request.session(:memcache)[:foo].should == "memcache-baz"
  end
  
end