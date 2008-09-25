require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "When recognizing requests," do
  
  describe "a route with fixation configured" do
    
    predicate_matchers[:allow_fixation] = :allow_fixation?

    it "should be able to allow fixation" do
      Merb::Router.prepare do
        match("/hello/:action/:id").to(:controller => "foo", :action => "fixoid").fixatable
      end

      matched_route_for("/hello/goodbye/tagging").should allow_fixation
    end

    it "should be able to disallow fixation" do
      Merb::Router.prepare do
        match("/hello/:action/:id").to(:controller => "foo", :action => "fixoid")
      end

      matched_route_for("/hello/goodbye/tagging").should_not allow_fixation
    end
    
  end
  
end