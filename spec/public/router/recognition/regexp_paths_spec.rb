require File.join(File.dirname(__FILE__), '..', "spec_helper")

describe "When recognizing requests," do

  describe "a route with a Regexp path condition" do
    
    it "should allow a regex expression" do
      Merb::Router.prepare do
        match(%r{^/foos?/(bar|baz)/([a-z0-9]+)}).to(:controller => "foo", :action => "[1]", :id => "[2]")
      end
      
      route_to("/foo/bar/baz").should  have_route(:controller => "foo", :action => "bar", :id => "baz")
      route_to("/foos/bar/baz").should have_route(:controller => "foo", :action => "bar", :id => "baz")
      lambda { route_to("/bars/foo/baz") }.should raise_not_found
    end
    
    it "should allow mixing regular expression paths with string paths" do
      Merb::Router.prepare do
        match(%r{^/(foo|bar)}).match("/baz").match(%r{/([a-z0-9]+)}).to(:controller => "[1]", :action => "baz", :id => "[2]")
      end
      
      route_to("/foo/baz/bar").should have_route(:controller => "foo", :action => "baz", :id => "bar")
      route_to("/bar/baz/foo").should have_route(:controller => "bar", :action => "baz", :id => "foo")
      lambda { route_to("/for/bar/baz") }.should raise_not_found
    end
    
    it "should allow mixing regular expression paths with string paths when nesting match blocks" do
      Merb::Router.prepare do
        match(%r{^/(foo|bar)}) do
          match("/baz") do
            match(%r{/([a-z0-9]+)}).to(:controller => "[1]", :action => "baz", :id => "[2]")
          end
        end
        
      end
      
      route_to("/foo/baz/bar").should have_route(:controller => "foo", :action => "baz", :id => "bar")
      route_to("/bar/baz/foo").should have_route(:controller => "bar", :action => "baz", :id => "foo")
      lambda { route_to("/for/bar/baz") }.should raise_not_found
    end
    
    it "should support inbound user agents" do
      Merb::Router.prepare do
        match(%r[^/foo/(.+)], :user_agent => /(MSIE|Gecko)/).to(:controller => "foo", :title => "[1]", :action => "show", :agent => ":user_agent[1]")
      end
      route_to("/foo/bar", :user_agent => "MSIE").should have_route(:controller => "foo", :action => "show", :title => "bar", :agent => "MSIE")
      lambda { route_to("/foo/bar", :user_agent => "Firefox") }.should raise_error(Merb::ControllerExceptions::NotFound)
    end
    
    it "should be able to handle http:// in the path" do
      Merb::Router.prepare do
        match(%r[^/(http://.*)]).to(:url => "[1]")
      end
      
      route_to("/http://another.tld/with/path").should have_route(:url => "http://another.tld/with/path")
    end
    
    it "should allow wrapping of nested routes all having shared OPTIONAL argument" do
      Merb::Router.prepare do
        match(/\/?(.*)?/).to(:language => "[1]") do
          match("/guides/:action/:id").to(:controller => "tour_guides")
        end
      end

      route_to('/guides/search/london').should have_route(:controller => 'tour_guides', :action => "search", :id => "london")
    end
  end

end