$START_OPTIONS = { :session_stores => ["cookie", "memory", "memcache"], :session_secret_key => "session-secret-key-here" }

require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "session_spec")
require File.join(File.dirname(__FILE__), "controllers", "sessions")

require 'memcached'
Merb::MemcacheSession.store = Memcached.new('127.0.0.1:11211', { :namespace => 'my_app' })

describe "An app with multiple session stores configured" do
  
  before(:all) { @controller_klass = Merb::Test::Fixtures::Controllers::MultipleSessionsController }
  
  it "should store cookie-based session data" do
    with_cookies(@controller_klass) do
      controller = dispatch_to(@controller_klass, :store_in_cookie)
      controller.request.session(:cookie)[:foo].should == "cookie-bar"
      controller.request.session[:foo].should == "cookie-bar" # defaults to the first registered store
    end
  end
  
  it "should retrieve cookie-based session data" do
    with_cookies(@controller_klass) do
      controller = dispatch_to(@controller_klass, :store_in_cookie)
      controller = dispatch_to(@controller_klass, :retrieve)
      controller.request.session(:cookie)[:foo].should == "cookie-bar"
      controller.request.session[:foo].should == "cookie-bar" # defaults to the first registered store
    end
  end
  
  it "should store memory-based session data" do
    with_cookies(@controller_klass) do
      controller = dispatch_to(@controller_klass, :store_in_memory)
      controller.request.session(:memory)[:foo].should == "memory-bar"
    end
  end
  
  it "should retrieve memory-based session data" do
    with_cookies(@controller_klass) do
      controller = dispatch_to(@controller_klass, :store_in_memory)
      controller = dispatch_to(@controller_klass, :retrieve)    
      controller.request.session(:memory)[:foo].should == "memory-bar"
    end
  end
  
  it "should store memcache-based session data" do
    with_cookies(@controller_klass) do
      controller = dispatch_to(@controller_klass, :store_in_memcache)
      controller.request.session(:memcache)[:foo].should == "memcache-bar"
    end
  end
  
  it "should retrieve memcache-based session data" do
    with_cookies(@controller_klass) do
      controller = dispatch_to(@controller_klass, :store_in_memcache)
      controller = dispatch_to(@controller_klass, :retrieve)
      controller.request.session(:memcache)[:foo].should == "memcache-bar"
    end
  end
   
  # TODO - _session_id cookies are clobbered atm - so this doesn't work yet
  # it "should allow you to use them simultaneously" do
  #   with_cookies(@controller_klass) do
  #     controller = dispatch_to(@controller_klass, :store_in_multiple)
  #     controller.request.session(:cookie)[:foo].should == "cookie-baz"
  #     
  #     controller = dispatch_to(@controller_klass, :retrieve)
  #     controller.request.session(:cookie)[:foo].should =="cookie-baz"
  #     controller.request.session(:memory)[:foo].should == "memory-baz"  
  #     controller.request.session(:memcache)[:foo].should == "memcache-baz"
  #   end
  # end
    
end