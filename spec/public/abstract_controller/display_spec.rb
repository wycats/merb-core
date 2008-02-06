require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::AbstractController, " displaying objects with templates" do

  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")
  end
  
  it "should allow you to pass an object" do
    dispatch_should_make_body("DisplayObject", "the index")
  end
  
  it "should allow you to pass an object with an action specified" do
    dispatch_should_make_body("DisplayObjectWithAction", "new action", :create)
  end
  
  it "should allow you to pass an object with a path specified for the template" do
    dispatch_should_make_body("DisplayObjectWithPath", "fooness")
  end
  
end