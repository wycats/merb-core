require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::AbstractController, " Partials" do
  
  it "should work with no options" do
    dispatch_should_make_body("BasicPartial", "Index Partial")
  end
  
  it "should work with :with" do
    dispatch_should_make_body("WithPartial", "Partial with With")
  end
  
  it "should work with :with and :as" do
    dispatch_should_make_body("WithAsPartial", "Partial with With and As")
  end
  
  it "should work with collections" do
    dispatch_should_make_body("PartialWithCollections", "Partial with collection")
  end
  
  it "should work with key/value pairs of locals" do
    dispatch_should_make_body("PartialWithLocals", "Partial with local variables")
  end
  
end