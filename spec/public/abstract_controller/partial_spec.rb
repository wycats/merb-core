require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::AbstractController, " Partials" do
  
  it "should work with no options" do
    dispatch_should_make_body("BasicPartial", "Index Partial")
  end
  
  it "should work with :with" do
    dispatch_should_make_body("WithPartial", "Partial with With")
  end

  it "should work with nil :with" do
    dispatch_should_make_body("WithNilPartial", "Partial with nil local")
  end
  
  it "should work with :with and :as" do
    dispatch_should_make_body("WithAsPartial", "Partial with With and As")
  end
  
  it "should work with collections" do
    dispatch_should_make_body("PartialWithCollections", "Partial with collection")
  end
  
  it "should work with collections and :as" do
    dispatch_should_make_body("PartialWithCollectionsAndAs", "Partial with collection")
  end
  
  it "should work with key/value pairs of locals" do
    dispatch_should_make_body("PartialWithLocals", "Partial with local variables")
  end
  
  it "should work with both collections and locals" do
    dispatch_should_make_body("PartialWithBoth", "Partial with c-o-l-l-e-c-t-i-o-n-")    
  end
  
  it "should work with both :with/:as and regular locals" do
    dispatch_should_make_body("PartialWithWithAndLocals", "Partial with with and locals")    
  end
  
  it "should work with a partial in another directory" do
    dispatch_should_make_body("PartialInAnotherDirectory", "Index Partial in another directory")
  end

  it "should work with nested partials with locals" do
    dispatch_should_make_body("NestedPartial", "first second first")
  end
  
  it "should work with multiple template roots" do
    dispatch_should_make_body("BasicPartialWithMultipleRoots", "Base Index: Alt Partial")
  end
  
  it "should be able to count collections" do
    dispatch_should_make_body("PartialWithCollectionsAndCounter", "Partial counting: 0/5 1/5 2/5 3/5 4/5 ")
  end
  
  it "should render a partial using an absolute path" do
    dispatch_should_make_body("WithAbsolutePartial", "Index Absolute Partial")
  end
  
end