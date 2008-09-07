require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "controllers", "sessions")

# The Merb::Session module gets mixed into Merb::SessionContainer to allow 
# app-level functionality (usually found in app/models/merb/session.rb)
module Merb
  module Session
    
    def awesome?
      self[:foo] == 'awesome'
    end
    
  end
end

describe "All session-store backends", :shared => true do
  
  it "should be instanciated using the 'generate' method" do
    @session_class.generate.should be_kind_of(@session_class)
  end
      
  it "should store the session_id" do
    @session.session_id.should match(/^[0-9a-f]{32}$/)
  end
  
  it "should have bracket accessors for setting data" do
    @session.should respond_to(:[]=)
    @session.should respond_to(:[])
    @session[:foo] = 'bar'
    @session[:foo].should == 'bar'
  end

end

describe "All session-stores mixed into Merb::Controller", :shared => true do
  
  before(:all) { @controller_klass = Merb::Test::Fixtures::Controllers::SessionsController }
  
  it "should represent the controller session" do
    with_cookies(@controller_klass) do
      controller = dispatch_to(@controller_klass, :index)
      controller.request.session.should be_kind_of(@session_class)
    end
  end
  
  it "should store session data" do
    session_store_type = @session_class.session_store_type.to_s
    with_cookies(@controller_klass) do
      controller = dispatch_to(@controller_klass, :index, :foo => session_store_type)
      controller.request.session[:foo].should == session_store_type
    end
  end
  
  it "should retrieve session data" do
    session_store_type = @session_class.session_store_type.to_s
    with_cookies(@controller_klass) do
      controller = dispatch_to(@controller_klass, :index, :foo => session_store_type)
      controller = dispatch_to(@controller_klass, :retrieve)
      controller.request.session[:foo].should == session_store_type
    end    
  end
  
  it "should allow regeneration of the session" do
    session_store_type = @session_class.session_store_type.to_s
    with_cookies(@controller_klass) do
      controller = dispatch_to(@controller_klass, :index, :foo => session_store_type)
      controller = dispatch_to(@controller_klass, :regenerate)
      controller = dispatch_to(@controller_klass, :retrieve)
      controller.request.session[:foo].should == session_store_type
    end    
  end
  
  it "should not set the Set-Cookie header when the session(_id) didn't change" do
    session_store_type = @session_class.session_store_type.to_s
    with_cookies(@controller_klass) do
      controller = dispatch_to(@controller_klass, :index, :foo => session_store_type)
      controller.headers["Set-Cookie"].should_not be_blank
      controller = dispatch_to(@controller_klass, :retrieve)
      controller.headers["Set-Cookie"].should be_blank
    end
  end
  
  it "should have mixed in Merb::Session methods" do
    with_cookies(@controller_klass) do
      controller = dispatch_to(@controller_klass, :index, :foo => 'awesome')
      controller.request.session.should respond_to(:awesome?)
      controller.request.session.should be_awesome
    end
  end
    
end