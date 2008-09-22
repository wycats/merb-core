require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Recognizing requests for deferred routes" do

  before :each do
    Merb::Router.prepare do      
      match("/deferred/:zoo").defer_to do |request, params|
        params.merge(:controller => "w00t") if params[:zoo]
      end
    end    
  end
  
  it "should match routes based on the incoming params" do
    route_to("/deferred/baz", :boo => "12").should have_route(:controller => "w00t", :zoo => "baz")
  end

  it "should not use the route if it does not match the defered block" do
    lambda { route_to("/deferred") }.should raise_not_found
  end
  
  it "should return the param hash returned by the block" do
    Merb::Router.prepare do
      match("/deferred").defer_to do |request, params|
        {:hello => "world"}
      end
    end
    
    route_to("/deferred").should have_route(:hello => "world")
  end
  
  it "should accept params" do
    Merb::Router.prepare do
      match("/").defer_to(:controller => "accounts") do |request, params|
        params.update(:action => "hello")
      end
    end
    
    route_to("/").should have_route(:controller => "accounts", :action => "hello")
  end
  
  it "should terminate the route definition" do
    lambda {
      Merb::Router.prepare do
        defer_to { }
        match("/").register
      end
    }.should raise_error(Merb::Router::Behavior::Error)
  end
  
  it "should be able to define routes after the deferred route" do
    Merb::Router.prepare do
      match("/deferred").defer_to do
        { :hello => "world" }
      end
      
      match("/").to(:foo => "bar")
    end
    
    route_to("/deferred").should have_route(:hello => "world")
    route_to("/").should         have_route(:foo => "bar")
  end
  
end