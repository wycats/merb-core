require File.join(File.dirname(__FILE__), "spec_helper")

describe "A plain route with no variables" do
  
  it "should return the parameters passed to #to" do
    prepare_route("/info", :controller => "info", :action => "foo")
    route_to("/info").should have_route(:controller => "info", :action => "foo", :id => nil)
  end
    
end

describe "A route with variables specified as :foo/:bar" do
  
  it "should work with :controller/:action/:id" do
    prepare_route("/foo/:action/:id", :controller => "foobar")
    route_to("/foo/bar/baz").should have_route(:controller => "foobar", :action => "bar", :id => "baz")
  end
  
  it "should work with :foo/:bar/:baz to :controller => ':foo/:bar'" do
    prepare_route("/:foo/:bar/:baz/:id", :controller => ":foo/:bar", :action => ":baz")
    route_to("/one/two/three/4").should have_route(:controller => "one/two", :action => "three", :id => "4")
  end
  
end

describe "A route containing block matchers" do
  
  it "should support block matchers as a path namespace" do
    Merb::Router.prepare do |r|
      r.match("/foo") do |path|
        path.match("/bar/:id").to(:controller => "foo/bar", :action => "bar")
      end
    end
    route_to("/foo/bar/1").should have_route(:controller => "foo/bar", :action => "bar", :id => "1")
  end
  
  it "should still support :variables in the to route from any level" do
    Merb::Router.prepare do |r|
      r.match("/foo/:bar") do |path|
        path.match("/:baz/:id").to(:controller => "foo", :action => ":id", :id => ":bar/:baz")
      end
    end
    route_to("/foo/hello/goodbye/zoo").should have_route(:controller => "foo", :action => "zoo", :id => "hello/goodbye")
  end
  
end

describe "A route containing block matchers for the 'to' section" do
  
  it "should point a bunch of 'from' segments to the same 'to'" do
    Merb::Router.prepare do |r|
      r.to(:controller => "foo") do |a|
        a.match("/hello/:action/:id").to(:tag => ":id")
      end
    end
    route_to("/hello/goodbye/tagging").should have_route(
      :controller => "foo", :action => "goodbye", :id => "tagging", :tag => "tagging"
    )
  end
  
end