require File.join(File.dirname(__FILE__), "spec_helper")
Controllers = Merb::Test::Fixtures::Controllers

describe Merb::Controller, "callable actions" do
  
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

describe Merb::Controller, "filtered params" do  
  it "removes filtered parameters from the log" do
    out = with_level(:info) do
      dispatch_to(Controllers::FilteredParams, :index, :username => "Awesome", :password => "sekrit")
    end
    out.should include_log(/Params:.*"username"\s*=>\s*"Awesome"/)
    out.should_not include_log(/"password"/)
  end
  
  it "doesn't put the parameters in the log in levels higher than info" do
    out = with_level(:warn) do
      dispatch_to(Controllers::FilteredParams, :index, :username => "Awesome", :password => "sekrit")
    end
    out.should_not include_log(/Params/)
  end
end

describe Merb::Controller, "records benchmarks" do
  it "collects benchmarks for the amount of time the action took" do
    controller = dispatch_to(Controllers::Base, :index)
    controller._benchmarks[:action_time].should be_kind_of(Numeric)
  end
end

describe Merb::Controller, "handles invalid actions" do
  it "raises if an action was not found" do
    calling { controller = dispatch_to(Controllers::Base, :awesome) }.
      should raise_error(Merb::ControllerExceptions::ActionNotFound,
      /Action.*awesome.*was not found in.*Base/)
  end
end

describe Merb::Controller, "handles invalid status codes" do
  it "raises if an invalid status is set" do
    calling { dispatch_to(Controllers::SetStatus, :index) }.
      should raise_error(ArgumentError, /was.*String/)
  end
end

describe Merb::Controller, "before/after dispatch callbacks" do
  it "are used for internal purposes" do
    controller = dispatch_to(Controllers::DispatchCallbacks, :index)
    controller.called_before.should be_true
    controller.called_after.should be_true
  end  
end