require File.join(File.dirname(__FILE__), "spec_helper")

describe "The default routes" do
  
  before :each do
    Merb::Router.prepare {|r| r.default_routes}
  end
    
  it "should match /foo to the Foo controller and index action" do
    route_to("/foo").should have_route(:controller => "foo", :action => "index", :id => nil)
  end
  
  it "should match /foo/bar to the Foo controller and the bar action" do
    route_to("/foo/bar").should have_route(:controller => "foo", :action => "bar", :id => nil)
  end
  
  it "should match /foo/bar/12 to the Foo controller, the bar action, and id of 12" do
    route_to("/foo/bar/12").should have_route(:controller => "foo", :action => "bar", :id => "12")
  end
  
end