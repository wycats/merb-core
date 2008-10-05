require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "When recognizing requests," do

  describe "a basic resource collection route" do
  
    before :each do
      Merb::Router.prepare do
        resources :blogposts
      end
    end
  
    it "should have an index action with an optional :format" do
      route_for('/blogposts').should           have_route(:controller => 'blogposts', :action => 'index', :id => nil, :format => nil)
      route_for('/blogposts/index').should     have_route(:controller => 'blogposts', :action => 'index', :id => nil, :format => nil)
      route_for('/blogposts.js').should        have_route(:controller => 'blogposts', :action => 'index', :id => nil, :format => "js")
      route_for('/blogposts/index.xml').should have_route(:controller => 'blogposts', :action => 'index', :id => nil, :format => "xml")
    end
  
    it "should have a create action with an optional :format" do
      route_for('/blogposts',    :method => :post).should have_route(:controller => 'blogposts', :action => 'create', :id => nil, :format => nil)
      route_for('/blogposts.js', :method => :post).should have_route(:controller => 'blogposts', :action => 'create', :id => nil, :format => "js")
    end

    it "should not match put or delete on the collection" do
      [:put, :delete].each do |method|
        lambda { route_for('/blogposts',    :method => method) }.should raise_not_found
        lambda { route_for('/blogposts.js', :method => method) }.should raise_not_found
      end
    end
  
    it "should have a new action with an optional :format" do
      route_for('/blogposts/new',    :method => :get).should have_route(:controller => 'blogposts', :action => 'new', :id => nil, :format => nil)
      route_for('/blogposts/new.js', :method => :get).should have_route(:controller => 'blogposts', :action => 'new', :id => nil, :format => "js")
    end
    
    it "should not match post on the new action" do
      lambda { route_for('/blogposts/new',     :method => :post) }.should raise_not_found
      lambda { route_for('/blogposts/new.xml', :method => :post) }.should raise_not_found
    end
  
    it "should have a show action with an optional :format" do
      route_for('/blogposts/1',     :method => :get).should have_route(:controller => 'blogposts', :action => 'show', :id => "1", :format => nil)
      route_for('/blogposts/1.css', :method => :get).should have_route(:controller => 'blogposts', :action => 'show', :id => "1", :format => "css")
    end
  
    it "should have an update action with an optional :format" do
      route_for('/blogposts/1',     :method => :put).should have_route(:controller => 'blogposts', :action => 'update', :id => "1", :format => nil)
      route_for('/blogposts/1.csv', :method => :put).should have_route(:controller => 'blogposts', :action => 'update', :id => "1", :format => "csv")
    end
  
    it "should have a destroy action with an optional :format" do
      route_for('/blogposts/1',     :method => :delete).should have_route(:controller => 'blogposts', :action => 'destroy', :id => "1", :format => nil)
      route_for('/blogposts/1.xxl', :method => :delete).should have_route(:controller => 'blogposts', :action => 'destroy', :id => "1", :format => 'xxl')
    end

    it "should have an edit action with an optional :format" do
      route_for('/blogposts/1/edit',     :method => :get).should have_route(:controller => 'blogposts', :action => 'edit', :id => "1", :format => nil)
      route_for('/blogposts/1/edit.rss', :method => :get).should have_route(:controller => 'blogposts', :action => 'edit', :id => "1", :format => "rss")
    end
    
    it "should not match post, put, or delete on the edit action" do
      [:put, :post, :delete].each do |method|
        lambda { route_for('/blogposts/edit',    :method => :post) }.should raise_not_found
        lambda { route_for('/blogposts/edit.hi', :method => :post) }.should raise_not_found
      end
    end
  
    it "should should have a delete action with an optional :format" do
      route_for('/blogposts/1/delete',     :method => :get).should have_route(:controller => 'blogposts', :action => 'delete', :id => "1", :format => nil)
      route_for('/blogposts/1/delete.mp3', :method => :get).should have_route(:controller => 'blogposts', :action => 'delete', :id => "1", :format => "mp3")
    end
    
    it "should not match post, put, or delete on the delete action" do
      [:put, :post, :delete].each do |method|
        lambda { route_for('/blogposts/delete',     :method => :post) }.should raise_not_found
        lambda { route_for('/blogposts/delete.flv', :method => :post) }.should raise_not_found
      end
    end
  end
  
  describe "a customized resource collection route" do
    
    it "should be able to change the controller that the resource points to" do
      Merb::Router.prepare do
        resources :blogposts, :controller => :posts
      end
      
      route_for('/blogposts').should                   have_route(:controller => "posts")
      route_for('/blogposts/1').should                 have_route(:controller => "posts")
      route_for('/blogposts', :method => :post).should have_route(:controller => "posts")
    end
    
    [:controller_prefix, :namespace].each do |option|
      it "should be able to specify the namespace with #{option.inspect}" do
        Merb::Router.prepare do
          resources :blogposts, option => "admin"
        end
        
        route_for('/blogposts').should have_route(:controller => "admin/blogposts")
      end
    end
    
    it "should be able to set the path prefix" do
      Merb::Router.prepare do
        resources :users, :path => "admins"
      end
      
      route_for("/admins").should have_route(:controller => "users", :action => "index")
    end
  end
  
  collection_routes = { :one  => :get, :two => :post, :three => :put, :four  => :delete }
  member_routes     = { :five => :get, :six => :post, :seven => :put, :eight => :delete }
  
  describe "a plural resource route with extra actions", :shared => true do
    
    # Loop through each method declared on the collection and make sure that they
    # are available only when the request is using the specified method
    collection_routes.each_pair do |action, method|
      it "should be able to add extra #{method} methods on the collection with an optional :format" do
        route_for("/users/#{action}",     :method => method).should have_route(:controller => "users", :action => "#{action}", :id => nil, :format => nil)
        route_for("/users/#{action}.xml", :method => method).should have_route(:controller => "users", :action => "#{action}", :id => nil, :format => "xml")
      end
      
      it "should still route /#{action} on get to show" do
        route_for("/users/#{action}").should have_route(:controller => "users", :action => "show", :id => "#{action}")
      end unless method == :get
      
      it "should still route /#{action} on put to update" do
        route_for("/users/#{action}", :method => :put).should have_route(:controller => "users", :action => "update", :id => "#{action}")
      end unless method == :put
      
      it "should still route /#{action} on delete to destroy" do
        route_for("/users/#{action}", :method => :delete).should have_route(:controller => "users", :action => "destroy", :id => "#{action}")
      end unless method == :delete
      
      it "should not match /#{action} on post to anything" do
        lambda { route_for("/users/#{action}", :method => :post) }.should raise_not_found
      end unless method == :post
    end
    
    member_routes.each_pair do |action, method|
      
      it "should be able to add extra #{method} methods on the member with an optional :format" do
        route_for("/users/2/#{action}",     :method => method).should have_route(:controller => "users", :action => "#{action}", :id => "2", :format => nil)
        route_for("/users/2/#{action}.xml", :method => method).should have_route(:controller => "users", :action => "#{action}", :id => "2", :format => "xml")
      end
      
      other_methods = [:get, :post, :put, :delete] - [method]
      other_methods.each do |other|
        
        it "should not route /#{action} on #{other} to anything" do
          lambda { route_for("/users/2/#{action}", :method => other) }.should raise_not_found
        end
        
      end
    end
    
  end
  
  describe "a plural resource with extra actions specified through the options" do
    
    before(:each) do
      Merb::Router.prepare do
        resources :users, :collection => collection_routes, :member => member_routes
      end
    end
    
    it_should_behave_like "a plural resource route with extra actions"
    
  end
  
  describe "a plural resource with extra actions specified in the block" do
    
    before(:each) do
      Merb::Router.prepare do
        resources :users do
          collection_routes.each { |name, method| collection name, :method => method, :to => "#{name}" }
          member_routes.each     { |name, method| member     name, :method => method, :to => "#{name}" }
        end
      end
    end
    
    it_should_behave_like "a plural resource route with extra actions"
    
    it "should work without the :to option" do
      Merb::Router.prepare do
        resources :users do
          collection :hello, :method => :get
          member     :hello, :method => :get
        end
      end
      
      route_for("/users/hello").should   have_route(:action => "hello")
      route_for("/users/1/hello").should have_route(:action => "hello")
    end
    
    it "should work without the :method option" do
      Merb::Router.prepare do
        resources :users do
          collection :hello, :to => "goodbye"
          member     :hello, :to => "goodbye"
        end
      end
      
      [:get, :post, :put, :delete].each do |method|
        route_for("/users/hello",   :method => method).should have_route(:action => "goodbye")
        route_for("/users/1/hello", :method => method).should have_route(:action => "goodbye")
      end
    end
    
    it "should be able to map the same path with different methods to different actions for collection routes" do
      Merb::Router.prepare do
        resources :users do
          collection :hello, :method => :get, :to => "collection_get_hello"
          collection :hello, :method => :put, :to => "collection_put_hello"
        end
      end
      
      route_for("/users/hello", :method => :get).should have_route(:controller => "users", :action => "collection_get_hello")
      route_for("/users/hello", :method => :put).should have_route(:controller => "users", :action => "collection_put_hello")
    end
    
    it "should be able to map the same path with different methods to different actions for member routes" do
      Merb::Router.prepare do
        resources :users do
          member :hello, :method => :get, :to => "member_get_hello"
          member :hello, :method => :put, :to => "member_put_hello"
        end
      end
      
      route_for("/users/9/hello", :method => :get).should have_route(:controller => "users", :id => "9", :action => "member_get_hello")
      route_for("/users/9/hello", :method => :put).should have_route(:controller => "users", :id => "9", :action => "member_put_hello")
    end
    
  end

  describe "a resource route with multiple custom keys" do
  
    before :each do
      Merb::Router.prepare do
        resources :emails, :keys => ["username", "domain"]
      end 
    end
    
    it "should match a get to /emails/bidule/merbivore_com to the  emails controller and the show action with username => 'bidule', domain => 'merbivore_com'" do
      route_for('/emails/bidule/merbivore_com', :method => :get).should have_route(:controller => 'emails', :action => 'show', :username => "bidule", :domain => "merbivore_com")
    end
    
    it "should match a put to /emails/bidule/merbivore_com to the  emails controller and the update action with username => 'bidule', domain => 'merbivore_com'" do
      route_for('/emails/bidule/merbivore_com', :method => :put).should have_route(:controller => 'emails', :action => 'update', :username => "bidule", :domain => "merbivore_com")
    end
    
    it "should match a delete to /emails/bidule/merbivore_com to the  emails controller and the destroy action with username => 'bidule', domain => 'merbivore_com'" do
      route_for('/emails/bidule/merbivore_com', :method => :delete).should have_route(:controller => 'emails', :action => 'destroy', :username => "bidule", :domain => "merbivore_com")
    end
    
    it "should match a get to /emails/bidule/merbivore_com/edit to the  emails controller and the destroy action with username => 'bidule', domain => 'merbivore_com'" do
      route_for('/emails/bidule/merbivore_com/edit', :method => :get).should have_route(:controller => 'emails', :action => 'edit', :username => "bidule", :domain => "merbivore_com")
    end
    
    it "should not match a put to /emails/bidule/merbivore_com/edit" do
      lambda { route_for('/emails/bidule/merbivore_com/edit', :method => :put) }.should raise_not_found
    end
    
    it "should match a get to /emails/bidule/merbivore_com/delete to the emails controller and the delete action with username => 'bidule', domain => 'merbivore_com'" do
      route_for('/emails/bidule/merbivore_com/delete', :method => :get).should have_route(:controller => 'emails', :action => 'delete', :username => "bidule", :domain => "merbivore_com")
    end
 
  end
  
  describe "a resource route with a single custom key" do
    
    [:key, :keys].each do |option|
      it "should use the specified key specified with #{option.inspect} in the params hash" do
        Merb::Router.prepare do
          resources :emails, option => :address
        end
        
        route_for("/emails/foobar",        :method => :get).should have_route(:controller => "emails", :action => "show",   :address => "foobar")
        route_for("/emails/foobar",        :method => :put).should have_route(:controller => "emails", :action => "update", :address => "foobar")
        route_for("/emails/foobar/edit",   :method => :get).should have_route(:controller => "emails", :action => "edit",   :address => "foobar")
        route_for("/emails/foobar/delete", :method => :get).should have_route(:controller => "emails", :action => "delete", :address => "foobar")
      end
    end
    
    it "should give precedence to :keys" do
      Merb::Router.prepare do
        resources :emails, :keys => :address, :key => :zomg
      end
      
      route_for("/emails/foobar",        :method => :get).should have_route(:controller => "emails", :action => "show",   :address => "foobar")
      route_for("/emails/foobar",        :method => :put).should have_route(:controller => "emails", :action => "update", :address => "foobar")
      route_for("/emails/foobar/edit",   :method => :get).should have_route(:controller => "emails", :action => "edit",   :address => "foobar")
      route_for("/emails/foobar/delete", :method => :get).should have_route(:controller => "emails", :action => "delete", :address => "foobar")
    end
    
  end
  
end