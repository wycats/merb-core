require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Recognizing requests for the routes with" do
  
  describe "a route with optional segments", :shared => true do
    
    it "should match when the required segment matches" do
      route_for("/hello").should have_route(:first => 'hello', :second => nil, :third => nil)
    end
    
    it "should match when the required and optional segment(s) match" do
      route_for("/hello/world/sweet").should have_route(:first => "hello", :second => "world", :third => "sweet")
    end
    
  end
  
  describe "a single optional segment" do
    before(:each) do
      Merb::Router.prepare do
        match("/:first(/:second/:third)").register
      end
    end
    
    it_should_behave_like "a route with optional segments"
    
    it "should not match the route if the optional segment is only partially present" do
      lambda { route_for("/hello/world") }.should raise_not_found
    end
    
    it "should not match the optional segment if the optional segment is present but doesn't match a named segment condition" do
      Merb::Router.prepare do
        match("/:first(/:second)", :second => /^\d+$/).register
      end
      
      lambda { route_for("/hello/world") }.should raise_not_found
    end
    
    it "should not match if the optional segment is present but not the required segment" do
      Merb::Router.prepare do
        match("/:first(/:second)", :first => /^[a-z]+$/, :second => /^\d+$/).register
      end
      
      lambda { route_for("/123") }.should raise_not_found
    end
  end
  
  describe "multiple optional segments" do
    before(:each) do
      Merb::Router.prepare do
        match("/:first(/:second)(/:third)").register
      end
    end
    
    it_should_behave_like "a route with optional segments"
    
    it "should match when one optional segment matches" do
      route_for("/hello/sweet").should have_route(:first => "hello", :second => "sweet")
    end
    
    it "should be able to distinguish the optional segments when there are conditions on them" do
      Merb::Router.prepare do
        match("/:first(/:second)(/:third)", :second => /^\d+$/).register
      end
      
      route_for("/hello/world").should have_route(:first => "hello", :second => nil, :third => "world")
      route_for("/hello/123").should have_route(:first => "hello", :second => "123", :third => nil)
    end
    
    it "should not match any of the optional segments if the segments can't be matched" do
      Merb::Router.prepare do
        match("(/:first/abc)(/:bar)").register
      end
      
      lambda { route_for("/abc/hello") }.should raise_not_found
      lambda { route_for("/hello/world/abc") }.should raise_not_found
    end
  end
  
  describe "nested optional segments" do
    before(:each) do
      Merb::Router.prepare do
        match("/:first(/:second(/:third))").register
      end
    end
    
    it_should_behave_like "a route with optional segments"
    
    it "should match when the first optional segment matches" do
      route_for("/hello/world").should have_route(:first => "hello", :second => "world")
    end
    
    it "should not match the nested optional group unless the containing optional group matches" do
      Merb::Router.prepare do
        match("/:first(/:second(/:third))", :second => /^\d+$/).to
      end
      
      lambda { route_for("/hello/world") }.should raise_not_found
    end
  end
  
  describe "nested match blocks with optional segments" do
    it "should allow wrapping of nested routes all having a shared optional segment" do
      Merb::Router.prepare do
        match("(/:language)") do
          match("/guides/:action/:id").to(:controller => "tour_guides")
        end
      end

      route_for('/guides/search/london').should have_route(:controller => 'tour_guides', :action => "search", :id => "london")
    end
  end
  
end