require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::Controller, " displaying objects based on mime type" do

  before do
    Merb::Router.prepare do |r|
      r.default_routes
    end
  end
  
  it "should default the mime-type to HTML (and raise since there's no to_html)" do
    running { dispatch_to(Merb::Test::Fixtures::Controllers::DisplayHtmlDefault, :index) }.should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end
  
  it "should use a template if specified" do
    dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithTemplate, :index).body.should == "Custom: Template"
  end
  
  it "should accept a layout argument" do
    dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithTemplateArgument, :index).body.should == "Custom Arg: Template"
  end
  
  it "should accept a template path argument" do
    dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithTemplateArgument, :index_by_arg).body.should == "Template"
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
  
  it "passes all options to serialization method like :to_json" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithSerializationOptions, :index, {}, :http_accept => "application/json")
    controller.body.should == "{ 'include': 'beer, jazz', 'exclude': 'idiots' }"
  end
  
  it "passes single argument to serialization method like :to_json" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithSerializationOptions, :index_that_passes_empty_hash, {}, :http_accept => "application/json")
    controller.body.should == "{ 'include': '', 'exclude': '' }"
  end
end