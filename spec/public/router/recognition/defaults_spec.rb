require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Recognizing requests for the routes with default values for variables" do
  
  it "should use the specified default value if the variable is not included in the path" do
    Merb::Router.prepare do
      defaults(:controller => "foos", :action => "bars").match("/").register
    end
    
    route_for("/").should have_route(:controller => "foos", :action => "bars")
  end
  
  it "should use the specified default value if the variable is included in the path but wasn't matched" do
    Merb::Router.prepare do
      defaults(:action => "index").match("/:controller(/:action)").register
    end
    
    route_for("/foos").should have_route(:controller => "foos", :action => "index")
  end
  
  it "should use the matched value for required variables" do
    Merb::Router.prepare do
      defaults(:action => "index").match("/:controller/:action").register
    end
    
    route_for("/foos/bar").should have_route(:controller => "foos", :action => "bar")
  end
  
  it "should use the matched value for optional variables" do
    Merb::Router.prepare do
      defaults(:action => "index").match("/:controller(/:action)").register
    end
    
    route_for("/foos/bar").should have_route(:controller => "foos", :action => "bar")
  end
  
  it "should use the params when there are some set" do
    Merb::Router.prepare do
      match("/go").defaults(:foo => "bar").to(:foo => "baz")
    end
    
    route_for("/go").should have_route(:foo => "baz")
  end
  
  it "should be used in constructed params when the optional segment wasn't matched" do
    Merb::Router.prepare do
      match("/go(/:foo)").defaults(:foo => "bar").to(:foo => "foo/:foo")
    end
    
    route_for("/go").should have_route(:foo => "foo/bar")
  end
  
  it "should combine multiple default params when nesting defaults" do
    Merb::Router.prepare do
      defaults(:controller => "home") do
        defaults(:action => "index").match("/(:controller/:action)").register
      end
    end
    
    route_for("/").should have_route(:controller => "home", :action => "index")
  end
  
  it "should yield the new builder object to the block" do
    Merb::Router.prepare do
      defaults(:controller => "home") do |d|
        d.defaults(:action => "index").match("/(:controller/:action)").register
      end
    end
    
    route_for("/").should have_route(:controller => "home", :action => "index")
  end
  
  it "should overwrite previously set default params with the new ones when nesting" do
    Merb::Router.prepare do
      defaults(:action => "index") do
        defaults(:action => "notindex").match("/:account(/:action)").register
      end
    end
    
    route_for("/awesome").should have_route(:account => "awesome", :action => "notindex")
  end
  
  it "should preserve previously set conditions" do
    Merb::Router.prepare do
      match("/blah") do
        defaults(:foo => "bar").to(:controller => "baz")
      end
    end
    
    route_for("/blah").should have_route(:controller => "baz", :foo => "bar")
  end
  
  it "should be preserved through condition blocks" do
    Merb::Router.prepare do
      defaults(:foo => "bar") do
        match("/go").register
      end
    end
    
    route_for("/go").should have_route(:foo => "bar")
  end
  
  it "should preserve previously set params" do
    Merb::Router.prepare do
      to(:controller => "bar") do
        defaults(:action => "baz").match("/go").register
      end
    end
    
    route_for("/go").should have_route(:controller => "bar", :action => "baz")
  end
  
  it "should be preserved through params blocks" do
    Merb::Router.prepare do
      defaults(:foo => "bar") do
        match("/go").to(:controller => "gos")
      end
    end
    
    route_for("/go").should have_route(:controller => "gos", :foo => "bar")
  end
end