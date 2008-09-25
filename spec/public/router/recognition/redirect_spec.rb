require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "When recognizing requests," do
  
  describe "a route that redirects" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/foo").redirect("/bar")
      end
    end
    
    predicate_matchers[:redirect] = :redirects?
    
    it "should be a redirect route" do
      matched_route_for("/foo").should redirect
    end
    
    it "should provide the url" do
      matched_route_for("/foo").redirect_url.should == "/bar"
    end
    
    it "should be a permanent redirect" do
      matched_route_for("/foo").redirect_status.should == 301
    end
    
    it "should be able to set the redirect as a temporary redirect" do
      Merb::Router.prepare do
        match("/foo").redirect("/bar", false)
      end
      
      matched_route_for("/foo").redirect_status.should == 302
    end
    
  end
  
end