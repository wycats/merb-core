$START_OPTIONS = { :session_store => "cookie", :session_secret_key => "session-secret-key-here" }

require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "session_spec")
require File.join(File.dirname(__FILE__), "controllers", "sessions")

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
 
  it "should be present in Merb::Request.registered_session_types" do
    Merb::Request.registered_session_types[:cookie].should == "Merb::CookieSession"
  end
 
  it "should represent the controller session" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::SessionsController, :index)
    controller.body.should == "cookie"
    controller.request.session.should be_kind_of(Merb::CookieSession)
  end
  
  it "should store session data" do
    store_sample_session
  end
  
  it "should return stored session data" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::SessionsController, :retrieve, {}, 
      Merb::Const::HTTP_COOKIE => "#{Merb::Request._session_id_key}=#{store_sample_session.to_cookie}")
    controller.request.session[:foo].should == "bar"
  end
  
  it "shouldn't allow tampering with cookie data" do
    session = store_sample_session
    original_checksum = session.to_cookie.split('--').last
    session[:foo] = "booz" # tamper with the data itself
    cookie_data, cookie_checksum = session.to_cookie.split('--')
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::SessionsController, :retrieve, {}, 
      Merb::Const::HTTP_COOKIE => "#{Merb::Request._session_id_key}=#{cookie_data}--#{original_checksum}")
    lambda { controller.request.session }.should raise_error(Merb::CookieSession::TamperedWithCookie)
  end
  
  it "shouldn't allow tampering with cookie fingerprints" do
    cookie_data, cookie_checksum = store_sample_session.to_cookie.split('--')
    cookie_checksum = cookie_checksum.reverse # tamper with the fingerprint
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::SessionsController, :retrieve, {}, 
      Merb::Const::HTTP_COOKIE => "#{Merb::Request._session_id_key}=#{cookie_data}--#{cookie_checksum}")
    lambda { controller.request.session }.should raise_error(Merb::CookieSession::TamperedWithCookie)
  end
  
  def store_sample_session
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::SessionsController, :index, :foo => "bar")
    controller.request.session[:foo].should == "bar"
    controller.request.session
  end
  
end