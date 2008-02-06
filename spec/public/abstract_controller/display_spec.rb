require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::AbstractController, " displaying objects" do

  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")
  end
  
  it "should support displaying objects with no layout" do
    dispatch_should_make_body("DisplayObject", "index")
  end
  
end