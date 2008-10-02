require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "When recognizing requests," do

  # predicate_matchers[:redirects] = :redirect
  
  describe "a route that redirects" do
    
    it "should set the request as a redirect" do
      Merb::Router.prepare do
        match("/foo").redirect("/bar")
      end
      
      route_for("/foo").should have_route(:url => "/bar", :status => 302)
    end
    
    it "should be able to set the redirect as a temporary redirect" do
      Merb::Router.prepare do
        match("/foo").redirect("/bar", :permanent => true)
      end
      
      route_for("/foo").should have_route(:url => "/bar", :status => 301)
    end
    
    it "should set the request as a redirect" do
      Merb::Router.prepare do
        match("/foo").redirect("/bar")
      end
      
      request_for("/foo").should be_redirects
    end
    
    it "should still redirect even if there was a deferred block assigned to the route" do
      Merb::Router.prepare do
        block = Proc.new { |r,p| p }
        defer(block) do
          match("/hello").redirect("/goodbye")
        end
      end
      
      route_for("/hello").should have_route(:url => "/goodbye", :status => 302)
      request_for("/hello").should be_redirects
    end
    
    it "should redirect to the URL in the deferred block" do
      Merb::Router.prepare do
        block = Proc.new { |r,p| redirect("/deferred-goodbye") }
        defer(block) do
          match("/hello").redirect("/goodbye")
        end
      end
      
      route_for("/hello").should have_route(:url => "/deferred-goodbye", :status => 302)
      request_for("/hello").should be_redirects
    end
    
  end
  
end