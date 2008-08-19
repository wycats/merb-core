require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "controllers", "sessions")

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
  
  it "should represent the controller session" do
    controller = dispatch_with_session_to(Merb::Test::Fixtures::Controllers::SessionsController, :index, @session)
    controller.body.should == @session.class.session_store_type
    controller.request.session.should be_kind_of(@session_class)
    controller.request.session.session_id.should == @session.session_id
    controller.request.session_id == @session.session_id
  end
  
  it "should store session data" do
    controller = dispatch_with_session_to(Merb::Test::Fixtures::Controllers::SessionsController, :index, @session, :foo => "bar")
    controller.request.session[:foo].should == "bar"
  end
  
  it "should return stored session data" do
    controller = dispatch_with_session_to(Merb::Test::Fixtures::Controllers::SessionsController, :retrieve, @session)
    controller.request.session[:foo].should == "bar"
  end
  
end