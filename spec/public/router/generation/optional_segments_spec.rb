require File.join(File.dirname(__FILE__), '..', "spec_helper")

describe "When generating URLs," do
  
  describe "a named route with a single optional segment" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/:foo(/:bar)").name(:optional)
      end
    end

    it "should not generate the optional segment when all segments are just strings" do
      Merb::Router.prepare do
        match("/hello(/world)").name(:optional)
      end

      url(:optional).should == "/hello"
    end

    it "should not add the optional segment when the optional segment is just a string" do
      Merb::Router.prepare do
        match("/:greets(/world)").name(:optional)
      end

      url(:optional, :greets => "goodbye").should == "/goodbye"
    end

    it "should only generate the route's required segment if it contains no variables" do
      Merb::Router.prepare do
        match("/hello(/:optional)").name(:optional)
      end

      url(:optional).should == "/hello"
    end

    it "should only generate the required segment of the route if the optional parameter is not provided" do
      url(:optional, :foo => "hello").should == "/hello"
    end

    it "should only generate the required segment of the route and add all extra parameters to the query string if the optional parameter is not provided" do
      url(:optional, :foo => "hello", :extra => "world").should == "/hello?extra=world"
    end

    it "should also generate the optional segment of the route if the parameter is provied" do
      url(:optional, :foo => "hello", :bar => "world").should == "/hello/world"
    end

    it "should generate the full optional segment of the route when there are multiple variables in the optional segment" do
      Merb::Router.prepare do
        match("/hello(/:foo/:bar)").name(:long_optional)
      end

      url(:long_optional, :foo => "world", :bar => "hello").should == "/hello/world/hello"
    end

    it "should not generate the optional segment of the route if all the parameters of that optional segment are not provided" do
      Merb::Router.prepare do
        match("/hello(/:foo/:bar)").name(:long_optional)
      end

      url(:long_optional, :foo => "world").should == "/hello?foo=world"
    end

    it "should raise an error if the required parameters are not provided" do
      lambda { url(:optional) }.should raise_error(Merb::Router::GenerationError)
    end

    it "should raise an error if the required parameters are not provided even if optional parameters are" do
      lambda { url(:optional, :bar => "hello") }.should raise_error(Merb::Router::GenerationError)
    end
    
  end
  
  describe "a named route with nested optional egments" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/:controller(/:action(/:id))").name(:nested)
      end
    end

    it "should generate the full route if all the necessary paramters are supplied" do
      url(:nested, :controller => "users", :action => "show", :id => 5).should == "/users/show/5"
    end

    it "should generate only the required segment if no optional paramters are supplied" do
      url(:nested, :controller => "users").should == "/users"
    end

    it "should generate the first optional level when deeper levels are not provided" do
      url(:nested, :controller => "users", :action => "show").should == "/users/show"
    end

    it "should add deeper level of optional parameters to the query string if a middle level is not provided" do
      url(:nested, :controller => "users", :id => 5).should == "/users?id=5"
    end

    it "should raise an error if the required segment is not provided" do
      lambda { url(:nested, :action => "show") }.should raise_error(Merb::Router::GenerationError)
      lambda { url(:nested, :id => 5) }.should raise_error(Merb::Router::GenerationError)
      lambda { url(:nested, :action => "show", :id => 5) }.should raise_error(Merb::Router::GenerationError)
    end

    it "should add extra parameters to the query string" do
      url(:nested, :controller => "users", :foo => "bar").should == "/users?foo=bar"
      url(:nested, :controller => "users", :action => "show", :foo => "bar").should == "/users/show?foo=bar"
      url(:nested, :controller => "users", :action => "show", :id => "2", :foo => "bar").should == "/users/show/2?foo=bar"
    end
    
  end
  
  describe "a named route with multiple optional segments" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/:controller(/:action)(.:format)").name(:multi)
      end
    end

    it "should generate the full route if all the parameters are provided" do
      url(:multi, :controller => "articles", :action => "recent", :format => "rss").should == "/articles/recent.rss"
    end

    it "should be able to generate the first optional segment without the second" do
      url(:multi, :controller => "articles", :action => "recent").should == "/articles/recent"
    end

    it "should be able to generate the second optional segment without the first" do
      url(:multi, :controller => "articles", :format => "xml").should == "/articles.xml"
    end
    
  end
  
  describe "a named route with multiple optional segments containing nested optional segments" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/:controller(/:action(/:id))(.:format)").name(:default)
      end
    end

    it "should generate the full route when all the parameters are provided" do
      url(:default, :controller => "posts", :action => "show", :id => "5", :format => :js).should ==
        "/posts/show/5.js"
    end

    it "should generate with just the required parameter" do
      url(:default, :controller => "posts").should == "/posts"
    end

    it "should be able to generate the first optional segment without the second" do
      url(:default, :controller => "posts", :action => "show").should == "/posts/show"
      url(:default, :controller => "posts", :action => "show", :id => "5").should == "/posts/show/5"
    end

    it "should be able to generate the second optional segment without the first" do
      url(:default, :controller => "posts", :format => "html").should == "/posts.html"
    end
    
  end
  
end