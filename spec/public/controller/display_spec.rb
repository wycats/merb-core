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

  it "should set headers['Location'] to string provided by :location" do
    dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithStringLocation, :index, {}, :http_accept => "application/json").headers['Location'].should =~ /some_resources/
  end

  it "should set the status to a code provided by :status" do
    dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithStatus, :index, {}, :http_accept => "application/json").status.should == 500
  end

  it "should use a template if specified" do
    dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithTemplate, :index).body.should match(/Custom: Template/)
  end

  it "overrides layout settings with render :layout => false" do
    dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithTemplate, :no_layout).body.should_not match(/Custom: Template/)
  end
  
  it "should accept an absolute template path argument - with the mimetype extension" do
    dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithTemplate, :absolute_with_mime).body.should == "Custom: HTML: Default"
  end
  
  it "should accept an absolute template path argument - without the mimetype extension" do
    dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithTemplate, :absolute_without_mime).body.should == "Custom: HTML: Default"
  end
  
  it "should accept a relative template path argument - with the mimetype extension" do
    dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithTemplate, :relative_with_mime).body.should == "Custom: HTML: Default"
  end
  
  it "should accept a relative template path argument - without the mimetype extension" do
    dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithTemplate, :relative_without_mime).body.should == "Custom: HTML: Default"
  end

  it "should accept a layout argument when calling to_*" do
    dispatch_to(Merb::Test::Fixtures::Controllers::DisplayWithLayout, :index, {}, 
      :http_accept => "application/json").body.should == "{custom_arg: { 'include': '', 'exclude': '' }}"
  end
  
  it "should accept a layout argument with a template" do
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
