require File.join(File.dirname(__FILE__), '..', "spec_helper")

describe "When generating URLs," do
  
  describe "a plain named route with no variables" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/hello/world").to(:controller => "hello", :action => "world").name(:simple)
      end
    end

    it "should generate with no parameters" do
      url(:simple).should == "/hello/world"
    end

    it "should append any parameters to the query string" do
      url(:simple, :foo => "bar").should == "/hello/world?foo=bar"
    end
    
  end
  
  describe "a named route with a variable and no conditions" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/:account/welcome").to(:controller => "home", :action => "welcome").name(:welcome)
      end
    end

    it "should generate a URL with a paramter passed for the variable" do
      url(:welcome, :account => "walruses").should == "/walruses/welcome"
    end
    
    it "should generate with a blank parameter" do
      url(:welcome, :account => "").should == "//welcome"
    end

    it "should append any extra parameters to the query string" do
      url(:welcome, :account => "seagulls", :like_walruses => "true").should == "/seagulls/welcome?like_walruses=true"
    end

    it "should raise an error if no parameters are passed" do
      lambda { url(:welcome) }.should raise_error(Merb::Router::GenerationError)
    end
    
    it "should raise an error if a nil parameter is passed" do
      lambda { url(:welcome, :account => nil) }.should raise_error(Merb::Router::GenerationError)
    end

    it "should raise an error if parameters are passed without :account" do
      lambda { url(:welcome, :foo => "bar") }.should raise_error(Merb::Router::GenerationError)
    end
    
  end
  
  describe "a named route with multiple variables and no conditions" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/:foo/:bar").to(:controller => "one", :action => "two").name(:foobar)
      end
    end

    it "should generate URL with parameters passed for both variables" do
      url(:foobar, :foo => "omg", :bar => "hi2u").should == "/omg/hi2u"
    end

    it "should append any extra parameters to the query string" do
      url(:foobar, :foo => "omg", :bar => "hi2u", :fiz => "what", :biz => "bat").should =~ %r[\?(fiz=what&biz=bat|biz=bat&fiz=what)$] # "/omg/hi2u?fiz=what&biz=bat"
    end
    
    it "should not append nil parameters to the query string" do
      url(:foobar, :foo => "omg", :bar => "hi2u", :fiz => nil).should == "/omg/hi2u"
    end

    it "should raise an error if the first variable is missing" do
      lambda { url(:foobar, :bar => "hi2u") }.should raise_error(Merb::Router::GenerationError)
    end

    it "should raise an error if the second variable is missing" do
      lambda { url(:foobar, :foo => "omg") }.should raise_error(Merb::Router::GenerationError)
    end

    it "should raise an error no variables are passed" do
      lambda { url(:foobar) }.should raise_error(Merb::Router::GenerationError)
    end
    
  end
  
  describe "a named route that has :controller and :action in the path and no conditions" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/:controller/:action").name(:default)
      end
    end

    it "should generate from any controller and action" do
      url(:default, :controller => "ilove", :action => "lamb").should == "/ilove/lamb"
    end

    it "should append any extra parameters to the query string" do
      url(:default, :controller => "di", :action => "fm", :quality => "rocks").should == "/di/fm?quality=rocks"
    end

    it "should require the controller" do
      lambda { url(:default, :action => "fm") }.should raise_error(Merb::Router::GenerationError)
    end

    it "should require the controller even if extra parameters are passed" do
      lambda { url(:default, :action => "fm", :random => "station") }.should raise_error(Merb::Router::GenerationError)
    end

    it "should require the action" do
      lambda { url(:default, :controller => "di") }.should raise_error(Merb::Router::GenerationError)
    end

    it "should require the action even if extra parameters are passed" do
      lambda { url(:default, :controller => "di", :random => "station") }.should raise_error(Merb::Router::GenerationError)
    end
    
  end
  
end