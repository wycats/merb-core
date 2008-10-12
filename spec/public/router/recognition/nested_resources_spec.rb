require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Recognizing requests for nested resources routes" do
  
  before(:each) do
    Merb::Router.prepare do
      
      resources :users do
        
        resources :comments, :collection => { :one => :get }, :member => { :two => :get } do
          collection :three, :to => "awesome"
          member     :four,  :to => "awesome"
          
          resources :replies, :collection => { :one => :get }, :member => { :two => :get } do
            collection :three, :to => "awesome"
            member     :four,  :to => "awesome"
          end
        end
        
        resource :profile, :member => { :one => :get } do
          member :two, :to => "awesome"
        end
      end
      
      resource :account do
        resources :images, :collection => { :one => :get }, :member => { :two => :get } do
          collection :three, :to => "awesome"
          member     :four,  :to => "awesome"
        end
        
        resource  :preference, :member => { :one => :get } do
          member :two, :to => "awesome"
        end
      end
      
      resources :domains, :keys => :domain do
        resources :emails, :keys => :username
      end
    end
  end
  
  it_should_be_a_resource_collection_route :comments, "/users/9", :user_id => "9"
  
  it_should_be_a_resource_collection_route :replies,  "/users/9/comments/5", :user_id => "9", :comment_id => "5"
  
  it_should_be_a_resource_object_route :profile, "/users/8", :user_id => "8"
  
  it_should_be_a_resource_collection_route :images, "/account"
  
  it_should_be_a_resource_object_route :preference, "/account"
  
  it "should match a get to /domains/merbivore_com/emails to the emails controller and index action with domain => 'merbivore_com" do
    route_for('/domains/merbivore_com/emails', :method => :get).should have_route(:controller => 'emails', :action => 'index', :username => nil, :domain => 'merbivore_com')
  end
  
end

describe "Recognizing requests for nested resources routes with custom matchers" do
  
  it "should convert the :id condition to :user_id" do
    Merb::Router.prepare do
      resources :users, :id => /[a-z]+/ do
        resources :comments
      end
    end
    
    route_for("/users/abc/comments/1").should have_route(:user_id => "abc")
    lambda { route_for('/users/123/comments/1') }.should raise_not_found
  end
  
  it "should leave single keys not named :id alone" do
    Merb::Router.prepare do
      resources :users, :key => :name, :name => /[a-z]+/ do
        resources :comments
      end
    end
    
    route_for("/users/abc/comments/1").should have_route(:name => "abc")
    lambda { route_for('/users/123/comments/1') }.should raise_not_found
  end
  
  it "should work with multi-key resources that have an :id as part of the identifier" do
    Merb::Router.prepare do
      resources :users, :key => [:name, :id], :id => /[a-z]+/ do
        resources :comments
      end
    end
    
    route_for("/users/abc/efg/comments/1").should have_route(:name => "abc", :user_id => "efg")
    lambda { route_for('/users/abc/123/comments/1') }.should raise_not_found
  end
  
  it "should work with mult-key resources" do
    Merb::Router.prepare do
      resources :users, :key => [:first, :last], :first => /[a-z]+/, :last => /[a-z]+\/[a-z]+/ do
        resources :comments
      end
    end
    
    route_for("/users/abc/efg/hij/comments/1").should have_route(:first => "abc", :last => "efg/hij")
    lambda { route_for('/users/abc/123/comments/1') }.should raise_not_found
    lambda { route_for('/users/abc/efg/comments/1') }.should raise_not_found
  end
  
end