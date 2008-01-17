require File.join(File.dirname(__FILE__), "spec_helper")

describe "The default Merb directory structure" do
  
  before :all do
    Merb::Config.setup(:merb_root => (File.dirname(__FILE__) / "directory"))
    Merb::BootLoader.run
  end
  
  it "should load in controllers" do
    calling { Base }.should_not raise_error
  end
  
  it "should be able to complete the dispatch cycle" do
    controller = dispatch_to(Base, :string)
    controller.body.should == "String"
  end
  
  it "should be able to complete the dispatch cycle with templates" do
    controller = dispatch_to(Base, :template)
    controller.body.should == "Template ERB"
  end
  
end

describe "Modifying the _template_path" do
  
  before :all do
    Merb::Config.setup(:merb_root => (File.dirname(__FILE__) / "directory"))
    Merb::BootLoader.run    
  end
  
  it "should move the templates to a new location" do
    controller = dispatch_to(Custom, :template)
    controller.body.should == "Wonderful Template"
  end
  
end