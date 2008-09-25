require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::Router do
  
  describe "#prepare" do
    
    it "should be able to compile an empty route table" do
      lambda do
        Merb::Router.prepare { }
      end.should_not raise_error(SyntaxError)
    end
    
    it "should evaluate the prepare block in context an object that provides builder methods" do
      Merb::Router.prepare do
        %w(
          match to defaults options fixatable
          name full_name defer_to default_routes
          namespace redirect resources resource
        ).each do |method|
          respond_to?(method).should == true
        end
      end
    end
    
    it "should use the default root_behavior if none is specified" do
      Merb::Router.prepare do
        match("/hello").to(:controller => "hello")
      end
      
      route_to("/hello").should have_route(:controller => "hello", :action => "index")
    end
    
    it "should use the root_behavior specified externally" do
      Merb::Router.root_behavior = Merb::Router.root_behavior.defaults(:controller => "default")
      Merb::Router.prepare do
        match("/hello").register
      end
      
      route_to("/hello").should have_route(:controller => "default", :action => "index")
    end
    
    it "should be able to chain root_behaviors" do
      Merb::Router.root_behavior = Merb::Router.root_behavior.defaults(:controller => "default")
      Merb::Router.root_behavior = Merb::Router.root_behavior.defaults(:action     => "default")
      Merb::Router.prepare do
        match("/hello").register
      end
      
      route_to("/hello").should have_route(:controller => "default", :action => "default")
    end
    
    it "should raise a friendly error when there is some :controller mismatching going on" do
      lambda {
        Merb::Router.prepare do
          match("/").to(:controller => "hello/:controller")
        end
      }.should raise_error(Merb::Router::GenerationError)
    end
  end

  describe "#append" do
    
    it "should prepare the routes" do
      Merb::Router.append do
        match("/hello").to(:controller => "hello")
      end
      
      route_to("/hello").should have_route(:controller => "hello")
    end
    
    it "should retain previously defined routes" do
      Merb::Router.prepare do
        match("/hello").to(:controller => "hello")
      end
      
      Merb::Router.append do
        match("/goodbye").to(:controller => "goodbye")
      end
      
      route_to("/hello").should have_route(:controller => "hello")
    end
    
    it "should not overwrite any routes" do
      Merb::Router.prepare do
        match("/hello").to(:controller => "first")
      end
      
      Merb::Router.append do
        match("/hello").to(:controller => "second")
      end
      
      route_to("/hello").should have_route(:controller => "first")
    end
    
  end
  
  describe "#prepend" do
    
    it "should prepare the routes" do
      Merb::Router.prepend do
        match("/hello").to(:controller => "hello")
      end
      
      route_to("/hello").should have_route(:controller => "hello")
    end
    
    it "should retain previously defined routes" do
      Merb::Router.prepare do
        match("/hello").to(:controller => "hello")
      end
      
      Merb::Router.prepend do
        match("/goodbye").to(:controller => "goodbye")
      end
      
      route_to("/hello").should have_route(:controller => "hello")
    end
    
    it "should overwrite any routes" do
      Merb::Router.prepare do
        match("/hello").to(:controller => "first")
      end
      
      Merb::Router.prepend do
        match("/hello").to(:controller => "second")
      end
      
      route_to("/hello").should have_route(:controller => "second")
    end
    
  end
  
  describe "#reset!" do
    
    before(:each) do      
      Merb::Router.prepare do
        resources :users
      end
      Merb::Router.reset!
    end
    
    it "should empty #routes and #named_routes" do
      Merb::Router.routes.should be_empty
      Merb::Router.named_routes.should be_empty
    end
    
    it "should not be able to match routes anymore" do
      lambda { route_to("/users") }
    end
    
  end

  describe "#match" do
    
    it "should raise an error if the routes were not compiled yet" do
      lambda { Merb::Router.match(simple_request) }.should raise_error(Merb::Router::NotCompiledError)
    end

  end

end