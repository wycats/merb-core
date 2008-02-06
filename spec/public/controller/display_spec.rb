require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::Controller, " displaying objects based on mime type" do

  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")    
    Merb::Router.prepare do |r|
      r.default_routes
    end
  end
  
  it "should default the mime-type to HTML" do
    #dispatch_to(Merb::Test::Fixtures::Controllers::DisplayHtmlDefault, :index).body.should == "HTML: Default"
    pending "Decide if there will be a to_html method on model instances?"
  end
  
  it "should use a template if specified" do
    # dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithTemplate, :index).body.should == "HTML: Default"
    pending "Decide if there will be a to_html method on model instances?"
  end

  it "should use other mime-types if they are provided on the class level" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::DisplayClassProvides, :index, {}, :http_accept => "application/xml")
    controller.body.should == "<XML:Model />"
  end

  it "should fail if none of the acceptable mime-types are available" do
    calling { dispatch_to(Merb::Test::Fixtures::Controllers::DisplayClassProvides, :index, {}, :http_accept => "application/json") }.
      should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end

  it "should use mime-types that are provided at the local level" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::DisplayLocalProvides, :index, {}, :http_accept => "application/xml")
    controller.body.should == "<XML:Model />"    
  end
  
end