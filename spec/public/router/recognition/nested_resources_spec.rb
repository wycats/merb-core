require File.join(File.dirname(__FILE__), "..", "spec_helper")

def it_should_be_a_resource_collection_route(name, prefix, params = {})
  it "should provide #{name} with an 'index' route" do
    route_for("#{prefix}/#{name}").should have_route(params.merge(:action => "index", :controller => "#{name}"))
  end
  
  it "should provide #{name} with an 'index' route when explicitly specified" do
    route_for("#{prefix}/#{name}/index").should have_route(params.merge(:action => "index", :controller => "#{name}"))
  end
  
  it "should provide #{name} with a 'new' route" do
    route_for("#{prefix}/#{name}/new").should have_route(params.merge(:action => "new", :controller => "#{name}"))
  end
  
  it "should provide #{name} with a 'create' route" do
    route_for("#{prefix}/#{name}", :method => :post).should have_route(params.merge(:action => "create", :controller => "#{name}"))
  end
  
  it "should provide #{name} with a 'show' route" do
    route_for("#{prefix}/#{name}/45").should have_route(params.merge(:action => "show", :controller => "#{name}", :id => "45"))
  end
  
  it "should provide #{name} with an 'edit' route" do
    route_for("#{prefix}/#{name}/45/edit").should have_route(params.merge(:action => "edit", :controller => "#{name}", :id => "45"))
  end
  
  it "should provide #{name} with an 'update' route" do
    route_for("#{prefix}/#{name}/45", :method => :put).should have_route(params.merge(:action => "update", :controller => "#{name}", :id => "45"))
  end
  
  it "should provide #{name} with a 'delete' route" do
    route_for("#{prefix}/#{name}/45/delete").should have_route(params.merge(:action => "delete", :controller => "#{name}", :id => "45"))
  end
  
  it "should provide #{name} with a 'destroy' route" do
    route_for("#{prefix}/#{name}/45", :method => :delete).should have_route(params.merge(:action => "destroy", :controller => "#{name}", :id => "45"))
  end
  
  # --- I decided that all the routes here will have the following ---
  
  it "should provide #{name} with a 'one' collection route" do
    route_for("#{prefix}/#{name}/one").should have_route(params.merge(:action => "one", :controller => "#{name}"))
  end
  
  it "should provide #{name} with a 'two' member route" do
    route_for("#{prefix}/#{name}/45/two").should have_route(params.merge(:action => "two", :controller => "#{name}", :id => "45"))
  end
  
  it "should provide #{name} with a 'three' collection route that maps the 'awesome' method" do
    route_for("#{prefix}/#{name}/three").should have_route(params.merge(:action => "awesome", :controller => "#{name}"))
  end
  
  it "should provide #{name} with a 'four' member route that maps to the 'awesome' method" do
    route_for("#{prefix}/#{name}/45/four").should have_route(params.merge(:action => "awesome", :controller => "#{name}", :id => "45"))
  end
end

def it_should_be_a_resource_object_route(name, prefix, params = {})
  controller = "#{name}s"
  
  it "should provide #{name} with a 'show' route" do
    route_for("#{prefix}/#{name}").should have_route(params.merge(:action => "show", :controller => controller))
  end
  
  it "should provide #{name} with an 'edit' route" do
    route_for("#{prefix}/#{name}/edit").should have_route(params.merge(:action => "edit", :controller => controller))
  end
  
  it "should provide #{name} with an 'update' route" do
    route_for("#{prefix}/#{name}", :method => :put).should have_route(params.merge(:action => "update", :controller => controller))
  end
  
  it "should provide #{name} with a 'delete' route" do
    route_for("#{prefix}/#{name}/delete").should have_route(params.merge(:action => "delete", :controller => controller))
  end
  
  it "should provide #{name} with a 'destroy' route" do
    route_for("#{prefix}/#{name}", :method => :delete).should have_route(params.merge(:action => "destroy", :controller => controller))
  end
  
  it "should provide #{name} with a 'one' member route" do
    route_for("#{prefix}/#{name}/one").should have_route(params.merge(:action => "one", :controller => controller))
  end
  
  it "should provide #{name} with a 'two' member route that maps to the 'awesome' method" do
    route_for("#{prefix}/#{name}/two").should have_route(params.merge(:action => "awesome", :controller => controller))
  end
end

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