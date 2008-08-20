$START_OPTIONS = { :session_store => "cookie", :session_secret_key => "session-secret-key-here" }

require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "session_spec")
require File.join(File.dirname(__FILE__), "controllers", "sessions")

require "merb-core/dispatch/session/cookie"

describe Merb::CookieSession do
  
  before do 
    @session_class = Merb::CookieSession
    @session = @session_class.generate
  end
  
  it_should_behave_like "All session-store backends"
  
  it "should have a session_store_type class attribute" do
    @session.class.session_store_type.should == :cookie
  end
  
end

describe Merb::CookieSession, "mixed into Merb::Controller" do
 
  it "should represent the controller session" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::SessionsController, :index)
    controller.body.should == "cookie"
    controller.request.session.should be_kind_of(Merb::CookieSession)
  end
  
  it "should store session data" do
    store_sample_session_data
  end
  
  it "should return stored session data" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::SessionsController, :retrieve, {}, 
      Merb::Const::HTTP_COOKIE => "#{Merb::Request._session_id_key}=#{store_sample_session_data}")
    controller.request.session[:foo].should == "bar"
  end
  
  def store_sample_session_data
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::SessionsController, :index, :foo => "bar")
    controller.request.session[:foo].should == "bar"
    controller.request.session.to_cookie
  end
  
end