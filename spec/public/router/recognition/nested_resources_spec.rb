require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Recognizing requests for nested resources routes" do
  
  before(:each) do
    Merb::Router.prepare do
      
      resources :blogposts do
        resources :comments do
          resources :versions
        end
      end
      
      resources :users do
        resources :comments
      end
      
      resource :foo do
        resources :comments
      end
      
      resources :domains, :keys => [:domain] do
        resources :emails, :keys => [:username]
      end
    end
  end
  
  it "should match a get to /blogposts/1/comments to the comments controller and index action with blogpost_id" do
    route_for('/blogposts/1/comments', :method => :get).should have_route(:controller => 'comments', :action => 'index', :id => nil, :blogpost_id => '1')
  end
  
  it "should match a get to /blogposts/1/comments/2/versions to the versions controller and index action with blogpost_id and comment_id" do
    route_for('/blogposts/1/comments/2/versions', :method => :get).should have_route(:controller => 'versions', :action => 'index', :id => nil, :blogpost_id => '1', :comment_id => '2')
  end
  
  it "should match a get to /users/1/comments to the comments controller and index action with user_id" do
    route_for('/users/1/comments', :method => :get).should have_route(:controller => 'comments', :action => 'index', :id => nil, :user_id => '1')
  end

  it "should match a get to /foo/comments to the comments controller and index action" do
    route_for('/foo/comments', :method => :get).should have_route(:controller => 'comments', :action => 'index', :id => nil)
  end
  
  it "should match a get to /domains/merbivore_com/emails to the emails controller and index action with domain => 'merbivore_com" do
     route_for('/domains/merbivore_com/emails', :method => :get).should have_route(:controller => 'emails', :action => 'index', :username => nil, :domain => 'merbivore_com')
  end
end