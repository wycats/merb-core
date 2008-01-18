require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::AbstractController, " rendering plain strings" do

  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")
  end

  it "should support rendering plain strings with no layout" do
    dispatch_should_make_body("RenderString", "index")
  end

  it "should support rendering plain strings with custom layouts" do
    dispatch_should_make_body("RenderStringCustomLayout", "Custom: index")
  end

  it "should support rendering plain strings with the application layout" do
    dispatch_should_make_body("RenderStringAppLayout", "App: index")
  end
  
  it "should support rendering plain strings with the controller layout" do
    dispatch_should_make_body("RenderStringControllerLayout", "Controller: index")
  end

end

describe Merb::AbstractController, " rendering templates" do

  it "should support rendering templates with no layout" do
    dispatch_should_make_body("RenderTemplate", "index")
  end

  it "should support rendering templates with custom layouts" do
    dispatch_should_make_body("RenderStringCustomLayout", "Custom: index")
  end
  
  it "should support rendering templates with the application layout" do
    dispatch_should_make_body("RenderTemplateAppLayout", "App: index")
  end
  
  it "should support rendering plain strings with the controller layout" do
    dispatch_should_make_body("RenderTemplateControllerLayout", "Controller: index")
  end

end