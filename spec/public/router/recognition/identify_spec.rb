require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "When recognizing requests," do
  
  it "should retain previously set params" do
    Merb::Router.prepare do
      with(:controller => "hellos") do
        identify :id do
          match("/:world").register
        end
      end
    end
    
    route_for("/worlds").should have_route(:controller => "hellos", :world => "worlds")
  end
  
  it "should retain previously set options" do
    Merb::Router.prepare do
     options(:controller_prefix => "hello") do
        identify :id do
          match("/").to(:controller => "world")
        end
      end
    end
    
    route_for("/").should have_route(:controller => "hello/world")
  end
  
  it "should retain previously set namespaces" do
    Merb::Router.prepare do
      namespace :admin do
        identify :id do
          match("/hello").to(:controller => "world")
        end
      end
    end
    
    route_for("/admin/hello").should have_route(:controller => "admin/world")
  end
  
  it "should retain previously set defaults" do
    Merb::Router.prepare do
      defaults(:foo => "bar") do
        identify :id do
          match("/(:foo)").to(:controller => "hello")
        end
      end
    end
    
    route_for("/").should have_route(:controller => "hello", :foo => "bar")
  end
  
end