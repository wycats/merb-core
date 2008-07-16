require File.join(File.dirname(__FILE__), "spec_helper")

describe "resources routes" do
  before :each do
    Merb::Router.prepare do |r|
      r.resource :foo
    end
  end
  
  it "should match a get to /foo to the blogposts controller and show action" do
    route_to('/foo', :method => :get).should have_route(:controller => 'foo', :action => 'show', :id => nil)
  end
  
  it "should match a post to /foo to the blogposts controller and create action" do
    route_to('/foo', :method => :post).should have_route(:controller => 'foo', :action => 'create', :id => nil)
  end
  
  it "should match a put to /foo to the blogposts controller and update action" do
    route_to('/foo', :method => :put).should have_route(:controller => 'foo', :action => 'update', :id => nil)
  end
  
  it "should match a delete to /foo to the blogposts controller and show action" do
    route_to('/foo', :method => :delete).should have_route(:controller => 'foo', :action => 'destroy', :id => nil)
  end
  
  it "should match a get to /foo/new to the blogposts controller and new action" do
    route_to('/foo/new', :method => :get).should have_route(:controller => 'foo', :action => 'new', :id => nil)
  end
  
  it "should match a get to /foo/edit to the blogposts controller and edit action" do
    route_to('/foo/edit', :method => :get).should have_route(:controller => 'foo', :action => 'edit', :id => nil)
  end
  
  it "should match a get to /foo/delete to the blogposts controller and delete action" do
    route_to('/foo/delete', :method => :get).should have_route(:controller => 'foo', :action => 'delete', :id => nil)
  end
end
