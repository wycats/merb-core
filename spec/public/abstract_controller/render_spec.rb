require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::AbstractController, " rendering plain strings" do

  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")
  end

	it "should render two thrown_contents into same object" do
    dispatch_should_make_body("RenderTwoThrowContents", "FooBar")		
	end

  it "should support rendering plain strings with no layout" do
    dispatch_should_make_body("RenderString", "the index")
  end

  it "should support rendering plain strings with custom layouts" do
    dispatch_should_make_body("RenderStringCustomLayout", "Custom: the index")
  end

  it "should support rendering plain strings with the application layout" do
    dispatch_should_make_body("RenderStringAppLayout", "App: the index")
  end
  
  it "should support rendering plain strings with the controller layout" do
    dispatch_should_make_body("RenderStringControllerLayout", "Controller: the index")
  end

  it "should support rendering plain strings with dynamic layouts" do
    dispatch_should_make_body("RenderStringDynamicLayout", "Custom: the index", :index)
    dispatch_should_make_body("RenderStringDynamicLayout", "Alt: the alt index", :alt_index)
  end
  
end

describe Merb::AbstractController, " rendering templates" do

  it "should support rendering templates with no layout" do
    dispatch_should_make_body("RenderTemplate", "the index")
  end

  it "should support rendering templates with custom layouts" do
    dispatch_should_make_body("RenderStringCustomLayout", "Custom: the index")
  end
  
  it "should support rendering templates with the application layout" do
    dispatch_should_make_body("RenderTemplateAppLayout", "App: the index")
  end
  
  it "should support rendering plain strings with the controller layout" do
    dispatch_should_make_body("RenderTemplateControllerLayout", "Controller: the index")
  end
  
  it "should support rendering templates without any layout (even if the default layout exists)" do
    dispatch_should_make_body("RenderNoDefaultAppLayout", "the index")
  end
  
  it "should inherit the layout setting from a parent controller class" do
    dispatch_should_make_body("RenderNoDefaultAppLayoutInherited", "the index")
  end

  it "should support reverting to the default layout" do
    dispatch_should_make_body("RenderDefaultAppLayoutInheritedOverride", "App: the index")
  end  

  it "should support rendering templates with a custom location" do
    dispatch_should_make_body("RenderTemplateCustomLocation", "Wonderful")
  end
  
  it "should support rendering templates from an absolute path location" do
    dispatch_should_make_body("RenderTemplateAbsolutePath", "Wonderful")
  end

  it "should support rendering templates with multiple roots" do
    dispatch_should_make_body("RenderTemplateMultipleRoots", "App: Multiple")
  end

  it "should support rendering templates with multiple roots, first root" do
    dispatch_should_make_body("RenderTemplateMultipleRoots", "default show", "show")
  end

  it "should support rendering templates with multiple roots and custom location" do
    dispatch_should_make_body("RenderTemplateMultipleRootsAndCustomLocation", "Woot.")
  end 

  it "should support rendering templates with multiple roots and custom location from an inherited controller" do
    dispatch_should_make_body("RenderTemplateMultipleRootsInherited", "Good.")
  end 

end