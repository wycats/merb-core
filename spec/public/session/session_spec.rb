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
  
  before(:all) { @controller_class = Merb::Test::Fixtures::Controllers::SessionsController }
  
  it "should represent the controller session" do
    with_cookies(@controller_class) do
      controller = dispatch_to(@controller_class, :index)
      controller.request.session.should be_kind_of(@session_class)
    end
  end
  
  it "should store and retrieve session data" do
    session_store_type = @session_class.session_store_type.to_s
    with_cookies(@controller_class) do
      controller = dispatch_to(@controller_class, :index, :foo => session_store_type)
      controller.request.session[:foo].should == session_store_type
      
      controller = dispatch_to(@controller_class, :retrieve)
      controller.request.session[:foo].should == session_store_type
      
      controller = dispatch_to(@controller_class, :index, :foo => "bar")
      controller = dispatch_to(@controller_class, :retrieve)
      controller.request.session[:foo].should == "bar"
    end
  end
    
end