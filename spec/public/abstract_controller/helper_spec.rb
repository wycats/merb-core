require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::AbstractController, " with capture and concat" do
  
  it "should support capture" do
    dispatch_should_make_body("Capture", "Capture")
  end
  
  it "should support capture with arguments" do
    dispatch_should_make_body("CaptureWithArgs", "Capture: one, two")
  end

  it "should support basic helpers that use capture with <%=" do
    dispatch_should_make_body("CaptureEq", "Pre. Beginning... Capturing... Done. Post.")
  end
  
  it "should support concat" do
    dispatch_should_make_body("Concat", "Concat")
  end
    
end
