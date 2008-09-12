require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "controllers", "sessions")

describe "An app without sessions enabled" do
  
  it "should raise an exception when accessing request.session" do
    lambda {
      controller = dispatch_to(Merb::Test::Fixtures::Controllers::SessionsController, :index)
    }.should raise_error(Merb::SessionMixin::NoSessionContainer)
  end
  
end