require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Recognizing requests for the default routes" do
  
  before :each do
    Merb::Router.prepare do
      default_routes
    end
  end
    
  it "should match /foo to the Foo controller and index action" do
    route_for("/foo").should have_route(:controller => "foo", :action => "index", :id => nil)
  end
  
  it "should match /foo/bar to the Foo controller and the bar action" do
    route_for("/foo/bar").should have_route(:controller => "foo", :action => "bar", :id => nil)
  end
  
  it "should match /foo/bar/12 to the Foo controller, the bar action, and id of 12" do
    route_for("/foo/bar/12").should have_route(:controller => "foo", :action => "bar", :id => "12")
  end
  
  it "should match /foo.xml to the Foo controller, index action, and xml format" do
    route_for("/foo.xml").should have_route(:controller => "foo", :action => "index", :format => "xml")
  end
  
  it "should match /foo.xml to the Foo controller, bar action, and xml format" do
    route_for("/foo/bar.xml").should have_route(:controller => "foo", :action => "bar", :format => "xml")
  end
  
  it "should match /foo.xml to the Foo controller, bar action, id 10, and xml format" do
    route_for("/foo/bar/10.xml").should have_route(:controller => "foo", :action => "bar", :id => "10", :format => "xml")
  end
  
end