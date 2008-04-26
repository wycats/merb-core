require File.join(File.dirname(__FILE__), "spec_helper")

Merb::Router.prepare do |r|
  r.resources :blogposts do |b|
    b.resources :comments do |c|
      c.resources :versions
    end
  end
  r.resources :users do |u|
    u.resources :comments
  end
  r.resource :foo do |f|
    f.resources :comments
  end
  r.resources :domains, :keys => [:domain] do |d|
    d.resources :emails, :keys => [:username]
  end
end

describe "nested resources routes" do
  
  it "should match a get to /blogposts/1/comments to the comments controller and index action with blogpost_id" do
    route_to('/blogposts/1/comments', :method => :get).should have_route(:controller => 'comments', :action => 'index', :id => nil, :blogpost_id => '1')
  end
  
  it "should match a get to /blogposts/1/comments/2/versions to the versions controller and index action with blogpost_id and comment_id" do
    route_to('/blogposts/1/comments/2/versions', :method => :get).should have_route(:controller => 'versions', :action => 'index', :id => nil, :blogpost_id => '1', :comment_id => '2')
  end
  
  it "should match a get to /users/1/comments to the comments controller and index action with user_id" do
    route_to('/users/1/comments', :method => :get).should have_route(:controller => 'comments', :action => 'index', :id => nil, :user_id => '1')
  end

  it "should match a get to /foo/comments to the comments controller and index action" do
    route_to('/foo/comments', :method => :get).should have_route(:controller => 'comments', :action => 'index', :id => nil)
  end
  
  it "should match a get to /domains/merbivore_com/emails to the emails controller and index action with domain => 'merbivore_com" do
     route_to('/domains/merbivore_com/emails', :method => :get).should have_route(:controller => 'emails', :action => 'index', :username => nil, :domain => 'merbivore_com')
  end
end