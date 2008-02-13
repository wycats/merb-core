require File.join(File.dirname(__FILE__), "spec_helper")

describe "resources routes" do
  before :each do
    Merb::Router.prepare do |r|
      r.resources :blogposts
    end
  end
  
  it "should match a get to /blogposts to the blogposts controller and index action" do
    route_to('/blogposts', :method => :get).should have_route(:controller => 'blogposts', :action => 'index', :id => nil)
  end
  
  it "should match a post to /blogposts to the blogposts controller and create action" do
    route_to('/blogposts', :method => :post).should have_route(:controller => 'blogposts', :action => 'create', :id => nil)
  end
  
  it "should match a get to /blogposts/new to the blogposts controller and the new action" do
    route_to('/blogposts/new', :method => :get).should have_route(:controller => 'blogposts', :action => 'new', :id => nil)
  end
  
  it "should match a get to /blogposts/1 ot the  blogposts controller and the show action with id 1" do
    route_to('/blogposts/1', :method => :get).should have_route(:controller => 'blogposts', :action => 'show', :id => "1")
  end
  
  it "should match a put to /blogposts/1 ot the  blogposts controller and the update action with id 1" do
    route_to('/blogposts/1', :method => :put).should have_route(:controller => 'blogposts', :action => 'update', :id => "1")
  end
  
  it "should match a delete to /blogposts/1 ot the  blogposts controller and the destroy action with id 1" do
    route_to('/blogposts/1', :method => :delete).should have_route(:controller => 'blogposts', :action => 'destroy', :id => "1")
  end

  it "should match a get to /blogposts/1/edit to the blogposts controller and the edit action with id 1" do
    route_to('/blogposts/1/edit', :method => :get).should have_route(:controller => 'blogposts', :action => 'edit', :id => "1")
  end
  
  it "should match a get to /blogposts/1;edit to the blogposts controller and the edit action with id 1" do
    route_to('/blogposts/1;edit', :method => :get).should have_route(:controller => 'blogposts', :action => 'edit', :id => "1")
  end
  
  it "should not match a put to /blogposts/1/edit" do
    # not sure which of these is the best way to specify what I mean - so they're both in...
    route_to('/blogposts/1/edit', :method => :put).should have_nil_route
    route_to('/blogposts/1/edit', :method => :put).should_not have_route(:controller => 'blogposts', :action => 'edit', :id => "1")
  end
  
  it "should not match a put to /blogposts/1;edit" do
    # not sure which of these is the best way to specify what I mean - so they're both in...
    route_to('/blogposts/1;edit', :method => :put).should have_nil_route
    route_to('/blogposts/1;edit', :method => :put).should_not have_route(:controller => 'blogposts', :action => 'edit', :id => "1")
  end
  
  it "should match a get to /blogposts/1/delete to the blogposts controller and the delete action with id 1" do
    route_to('/blogposts/1/delete', :method => :get).should have_route(:controller => 'blogposts', :action => 'delete', :id => "1")
  end
end