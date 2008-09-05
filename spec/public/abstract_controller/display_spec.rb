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
 
  it "should allow you to pass an object with a path specified for the template via opts" do
    dispatch_should_make_body("DisplayObjectWithPathViaOpts", "fooness")
  end

  it "should allow you to pass an object using multiple template root" do
    dispatch_should_make_body("DisplayObjectWithMultipleRoots", "App: new index")
  end

  it "should allow you to pass an object using multiple template root, with layout" do
    dispatch_should_make_body("DisplayObjectWithMultipleRoots", "Alt: new show", "show")
  end

  it "should allow you to pass an object using multiple template root, without layout" do
    dispatch_should_make_body("DisplayObjectWithMultipleRoots", "fooness", "another")
  end

end
