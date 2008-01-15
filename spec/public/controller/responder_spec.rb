require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::Controller, " responds" do
  
  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")    
    Merb::Router.prepare do |r|
      r.default_routes
    end
  end
  
  it "should default the mime-type to HTML" do
    dispatch_to(Merb::Test::Fixtures::TestHtmlDefault, :index).body.should == "HTML: Default"
  end

  it "should use other mime-types if they are provided on the class level" do
    controller = dispatch_to(Merb::Test::Fixtures::TestClassProvides, :index, {}, :http_accept => "application/xml")
    controller.body.should == "<XML:Class provides='true' />"
  end

  it "should fail if none of the acceptable mime-types are available" do
    calling { dispatch_to(Merb::Test::Fixtures::TestClassProvides, :index, {}, :http_accept => "application/json") }.
      should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end
  
  it "should use mime-types that are provided at the local level" do
    controller = dispatch_to(Merb::Test::Fixtures::TestLocalProvides, :index, {}, :http_accept => "application/xml")
    controller.body.should == "<XML:Local provides='true' />"    
  end
    
end