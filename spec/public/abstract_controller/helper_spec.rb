require File.join(File.dirname(__FILE__), "spec_helper")
startup_merb

describe Merb::AbstractController, " with capture and concat" do
  
  it "should support capture" do
    dispatch_should_make_body("Capture", "Capture")
  end
  
  it "should support capture with arguments" do
    dispatch_should_make_body("CaptureWithArgs", "Capture: one, two")
  end

  it "should support capturing the return value of a non-template block" do
    dispatch_should_make_body("CaptureReturnValue", "Capture")
  end

  it "should support capturing the return value of a non-template block" do
    dispatch_should_make_body("CaptureNonStringReturnValue", "Captured ''")
  end

  it "should support basic helpers that use capture with <%=" do
    dispatch_should_make_body("CaptureEq", "Pre. Beginning... Capturing... Done. Post.")
  end
  
  it "should support concat" do
    dispatch_should_make_body("Concat", "Concat")
  end
    
end
