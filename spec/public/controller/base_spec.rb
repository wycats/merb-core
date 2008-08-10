require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::Controller, " callable actions" do
  
  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")    
    Merb::Router.prepare do |r|
      r.default_routes
    end
  end
  
  it "has no any callable actions by default" do
    Merb::Controller.callable_actions.should be_empty
  end
  
  it "sets body on dispatch to callable action" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::Base, :index)
    controller.body.should == "index"
  end

  it "sets status on dispatch to callable action" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::Base, :index)
    controller.status.should == 200
  end

  it "should not dispatch to hidden actions" do
    calling { dispatch_to(Merb::Test::Fixtures::Controllers::Base, :hidden) }.
      should raise_error(Merb::ControllerExceptions::ActionNotFound)
  end
  
  it "should dispatch to included methods with show_action called" do
    dispatch_to(Merb::Test::Fixtures::Controllers::Base, :baz).body.should == "baz"
  end

  it "should not dispatch to included methods with show_action not called" do
    calling { dispatch_to(Merb::Test::Fixtures::Controllers::Base, :bat) }.
      should raise_error(Merb::ControllerExceptions::ActionNotFound)
  end
 
end
