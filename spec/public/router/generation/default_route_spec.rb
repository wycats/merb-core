require File.join(File.dirname(__FILE__), '..', "spec_helper")

describe "When generating URLs," do
  
  describe "the default route" do
    
    it "should be able to generate from the various combinations" do
      Merb::Router.prepare do
        default_routes
      end

      url(:controller => "hello").should                              == "/hello"
      url(:controller => "hello", :action => "index").should          == "/hello/index"
      url(:controller => "hello", :action => "world").should          == "/hello/world"
      url(:controller => "hello", :format => :html).should            == "/hello.html"
      url(:controller => "zomg", :action => "hi2u", :id => 12).should == "/zomg/hi2u/12"
    end
    
    # it "should be able to generate spiced up default routes" do
    #   Merb::Router.prepare do |r|
    #     r.match("/:account/:controller(/:action(/:id))(.:format)").to.name(:default)
    #   end
    #   
    #   url(:account => "ohyeah", :controller => "hello").should == "/ohyeah/hello"
    #   url(:account => "ohyeah", :controller => "hello", :action => "world").should == "/ohyeah/hello/world"
    #   url(:account => "ohyeah", :controller => "hello", :format => :html).should == "/ohyeah/hello.html"
    #   
    #   url(:account => "ohyeah", :controller => "zomg", :action => "hi2u", :id => 12).should == "/ohyeah/zomg/hi2u/12"
    
  end
  
end