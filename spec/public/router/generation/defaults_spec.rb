require File.join(File.dirname(__FILE__), '..', "spec_helper")

describe "When generating URLs," do
  
  describe "a route default values for variable segments" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/(:foobar)").defaults(:foobar => "foo").name(:with_default)
      end
    end
    
    it "should generate the route normally" do
      url(:with_default).should                     == "/"
      url(:with_default, :foobar => "hello").should == "/hello"
    end
    
  end
  
end