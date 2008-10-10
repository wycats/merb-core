require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "When recognizing requests," do

  # predicate_matchers[:redirects] = :redirect
  
  describe "a route that redirects" do
    
    it "should set the request as a redirect" do
      Merb::Router.prepare do
        match("/foo").redirect("/bar")
      end
      
      route_for("/foo").should have_rack(:status => 302, :headers => { "Location" => "/bar" })
    end
    
    it "should be able to set the redirect as a temporary redirect" do
      Merb::Router.prepare do
        match("/foo").redirect("/bar", :permanent => true)
      end
      
      route_for("/foo").should have_rack(:status => 301, :headers => { "Location" => "/bar" })
    end
    
    it "should still redirect even if there was a deferred block assigned to the route" do
      Merb::Router.prepare do
        block = Proc.new { |r,p| p }
        defer(block) do
          match("/hello").redirect("/goodbye")
        end
      end
      
      route_for("/hello").should have_rack(:status => 302, :headers => { "Location" => "/goodbye" })
    end
    
    it "should redirect to the URL in the deferred block" do
      Merb::Router.prepare do
        block = Proc.new { |r,p| redirect("/deferred-goodbye") }
        defer(block) do
          match("/hello").redirect("/goodbye")
        end
      end
      
      route_for("/hello").should have_rack(:status => 302, :headers => { "Location" => "/deferred-goodbye" })
    end
    
  end
  
end