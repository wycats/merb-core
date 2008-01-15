require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::AbstractController, " rendering plain strings" do

  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")
  end

  it "should support rendering plain strings with no layout" do
    dispatch_should_make_body("TestRenderString", "index")
  end

  it "should support rendering plain strings with custom layouts" do
    dispatch_should_make_body("TestRenderStringCustomLayout", "Custom: index")
  end

  it "should support rendering plain strings with the application layout" do
    layout_path = Merb.dir_for(:layout)
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layout_test")
    dispatch_should_make_body("TestRenderStringAppLayout", "App: index")
    Merb.push_path(:layout, layout_path)    
  end
  
  it "should support rendering plain strings with the controller layout" do
    layout_path = Merb.dir_for(:layout)
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layout_test")
    dispatch_should_make_body("TestRenderStringControllerLayout", "Controller: index")
    Merb.push_path(:layout, layout_path)
  end

end

describe Merb::AbstractController, " rendering templates" do

  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")
  end

  it "should support rendering templates with no layout" do
    dispatch_should_make_body("TestRenderTemplate", "index")
  end

  it "should support rendering templates with custom layouts" do
    dispatch_should_make_body("TestRenderStringCustomLayout", "Custom: index")
  end
  
  it "should support rendering templates with the application layout" do
    layout_path = Merb.dir_for(:layout)
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layout_test")
    dispatch_should_make_body("TestRenderTemplateAppLayout", "App: index")
    Merb.push_path(:layout, layout_path)    
  end
  
  it "should support rendering plain strings with the controller layout" do
    layout_path = Merb.dir_for(:layout)
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layout_test")
    dispatch_should_make_body("TestRenderTemplateControllerLayout", "Controller: index")
    Merb.push_path(:layout, layout_path)
  end

end