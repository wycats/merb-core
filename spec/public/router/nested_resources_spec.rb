require File.join(File.dirname(__FILE__), "spec_helper")

describe "nested resources routes" do
  before :each do
    Merb::Router.prepare do |r|
      r.resources :blogposts do |b|
        b.resources :comments
      end
      r.resources :users do |u|
        u.resources :comments
      end
      r.resource :foo do |f|
        f.resources :comments
      end
    end
  end
  
  it "should match a get to /blogposts/1/comments to the comments controller and index action with blogpost_id" do
    route_to('/blogposts/1/comments', :method => :get).should have_route(:controller => 'comments', :action => 'index', :id => nil, :blogpost_id => '1')
  end
  
  it "should match a get to /users/1/comments to the comments controller and index action with user_id" do
    route_to('/users/1/comments', :method => :get).should have_route(:controller => 'comments', :action => 'index', :id => nil, :user_id => '1')
  end

  it "should match a get to /foo/comments to the comments controller and index action" do
    route_to('/foo/comments', :method => :get).should have_route(:controller => 'comments', :action => 'index', :id => nil)
  end
end