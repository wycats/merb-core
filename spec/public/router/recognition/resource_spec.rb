require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "When recognizing requests," do
  
  describe "a basic singular resource route" do
    
    before :each do
      Merb::Router.prepare do
        resource :foo
      end
    end

    it "should match a get to /foo to the blogposts controller and show action" do
      route_for('/foo', :method => :get).should have_route(:controller => 'foos', :action => 'show', :id => nil)
    end

    it "should match a post to /foo to the blogposts controller and create action" do
      route_for('/foo', :method => :post).should have_route(:controller => 'foos', :action => 'create', :id => nil)
    end

    it "should match a put to /foo to the blogposts controller and update action" do
      route_for('/foo', :method => :put).should have_route(:controller => 'foos', :action => 'update', :id => nil)
    end

    it "should match a delete to /foo to the blogposts controller and show action" do
      route_for('/foo', :method => :delete).should have_route(:controller => 'foos', :action => 'destroy', :id => nil)
    end

    it "should match a get to /foo/new to the blogposts controller and new action" do
      route_for('/foo/new', :method => :get).should have_route(:controller => 'foos', :action => 'new', :id => nil)
    end

    it "should match a get to /foo/edit to the blogposts controller and edit action" do
      route_for('/foo/edit', :method => :get).should have_route(:controller => 'foos', :action => 'edit', :id => nil)
    end

    it "should match a get to /foo/delete to the blogposts controller and delete action" do
      route_for('/foo/delete', :method => :get).should have_route(:controller => 'foos', :action => 'delete', :id => nil)
    end
    
  end
  
  describe "a customized singular resource route" do
    
    it "should be able to change the controller that the resource points to" do
      Merb::Router.prepare do
        resource :foo, :controller => :bars
      end
      
      route_for('/foo').should                   have_route(:controller => "bars")
      route_for('/foo', :method => :post).should have_route(:controller => "bars")
    end
    
    [:controller_prefix, :namespace].each do |option|
      it "should be able to specify the namespace with #{option.inspect}" do
        Merb::Router.prepare do
          resource :foo, option => "admin"
        end
        
        route_for('/foo').should have_route(:controller => "admin/foos")
      end
    end
    
    it "should be able to set the path prefix" do
      Merb::Router.prepare do
        resource :foo, :path => "bar"
      end
      
      route_for("/bar").should have_route(:controller => "foos", :action => "show")
    end
    
  end
  
  member_routes = { :five => :get, :six => :post, :seven => :put, :eight => :delete }
  
  describe "a singular resource route with extra actions", :shared => true do
    
    member_routes.each_pair do |action, method|
      
      it "should be able to add extra #{method} methods on the member with an optional :format" do
        route_for("/foo/#{action}",     :method => method).should have_route(:controller => "foos", :action => "#{action}", :format => nil)
        route_for("/foo/#{action}.xml", :method => method).should have_route(:controller => "foos", :action => "#{action}", :format => "xml")
      end
      
      other_methods = [:get, :post, :put, :delete] - [method]
      other_methods.each do |other|
        
        it "should not route /#{action} on #{other} to anything" do
          lambda { route_for("/foo/#{action}", :method => other) }.should raise_not_found
        end
        
      end
    end
    
  end
  
  describe "a singular resource with extra actions specified through the options" do
    
    before(:each) do
      Merb::Router.prepare do
        resource :foo, :member => member_routes
      end
    end
    
    it_should_behave_like "a singular resource route with extra actions"
    
  end
  
  describe "a singular resource with extra actions specified in the block" do
    
    before(:each) do
      Merb::Router.prepare do
        resource :foo do
          member_routes.each { |name, method| member name, :method => method, :to => "#{name}" }
        end
      end
    end
    
    it_should_behave_like "a singular resource route with extra actions"
    
    it "should work without the :to option" do
      Merb::Router.prepare do
        resource :foo do
          member :hello, :method => :get
        end
      end
      
      route_for("/foo/hello").should have_route(:action => "hello")
    end
    
    it "should work without the :method option" do
      Merb::Router.prepare do
        resource :foo do
          member :hello, :to => "goodbye"
        end
      end
      
      [:get, :post, :put, :delete].each do |method|
        route_for("/foo/hello", :method => method).should have_route(:action => "goodbye")
      end
    end
    
    it "should be able to map the same path with different methods to different actions for member routes" do
      Merb::Router.prepare do
        resource :foo do
          member :hello, :method => :get, :to => "member_get_hello"
          member :hello, :method => :put, :to => "member_put_hello"
        end
      end
      
      route_for("/foo/hello", :method => :get).should have_route(:controller => "foos", :action => "member_get_hello")
      route_for("/foo/hello", :method => :put).should have_route(:controller => "foos", :action => "member_put_hello")
    end
    
  end
  
end
