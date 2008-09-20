require File.join(File.dirname(__FILE__), '..', "spec_helper")

describe "When generating URLs when there are request params available," do
  
  describe "a simple route" do
    
    before(:each) do
      @request_params = { :project => "awesomo" }
    end
    
    it "should always try to pull required params from the request if they are missing" do
      Merb::Router.prepare do
        match("/:project/:article").name(:article)
      end
      
      url(:article, :article => "why-carl-is-awesome").should == "/awesomo/why-carl-is-awesome"
    end
    
    it "should not require any params when all the required params are available in the request" do
      Merb::Router.prepare do
        match("/:project").name(:account)
      end
      
      url(:account).should == "/awesomo"
    end
    
    it "should not append the extra request parameters to the query string" do
      @request_params.merge! :never => "see"
      
      Merb::Router.prepare do
        match("/hello").name(:simple)
      end
      
      url(:simple).should == "/hello"
    end
    
    it "should not generate optional segments even if all the params are availabe in the request if no element is provided" do
      @request_params.merge! :one => "uno", :two => "dos", :three => "tres"
      
      Merb::Router.prepare do
        match("/hello(/:one/:two/:three)").name(:sequential)
        match("/hello(/:one(/:two(/:three)))").name(:nested)
      end
      
      url(:sequential).should == "/hello"
      url(:nested).should     == "/hello"
    end
    
    it "should generate the optional segments if an element from it is specified" do
      @request_params.merge! :one => "uno", :two => "dos", :three => "tres"
      
      Merb::Router.prepare do
        match("/hello(/:one/:two/:three)").name(:sequential)
        match("/hello(/:one(/:two(/:three)))").name(:nested)
      end
      
      url(:sequential, :one   => "hi").should == "/hello/hi/dos/tres"
      url(:sequential, :two   => "hi").should == "/hello/uno/hi/tres"
      url(:sequential, :three => "hi").should == "/hello/uno/dos/hi"
      url(:nested,     :one   => "hi").should == "/hello/hi"
      url(:nested,     :two   => "hi").should == "/hello/uno/hi"
      url(:nested,     :three => "hi").should == "/hello/uno/dos/hi"
    end
    
  end
  
  describe "a route with segment conditions" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/:one(/:two/:three(/:four))", :one => /^\d+$/, :two => /^\d+$/, :three => /^\d+$/, :four => /^\d+$/).name(:numbers)
      end
    end
    
    it "should use the request params if using it will satisfy all the routes' conditions" do
      @request_params = { :one => '1', :two => '2' }
      url(:numbers, :three => '3').should == "/1/2/3"
    end
    
    it "should never generate paths that don't match the conditions and append passed params that didn't match to the query string" do
      @request_params = { :one => '1', :two => 'two' }
      url(:numbers, :three => '3').should == '/1?three=3'
      
      @request_params = { :one => "1", :two => "2", :three => "3" }
      url(:numbers, :four => "fouryo").should == "/1/2/3?four=fouryo"
    end
    
  end
  
  describe "a default route generated when there are request params available" do
    
    before(:each) do
      Merb::Router.prepare do
        default_routes
      end
      
      @request_params = { :controller => "articles", :action => "show", :id => "10" }
    end
    
    [ :including, :excluding ].each do |option|
      
      describe "#{option} a :format param" do
        
        before(:each) do
          @request_params.merge! :format => :xml if option == :including
        end
        
        it "should generate the route just the same when all params are supplied" do
          url(:controller => "articles", :action => "edit", :id => "8").should == "/articles/edit/8"
          url(:controller => "articles", :action => "index").should            == "/articles/index"
          url(:controller => "users").should                                   == "/users"
          url(:controller => "users", :action => "show").should                == "/users/show"
          url(:controller => "users", :action => "show", :id => 1).should      == "/users/show/1"
        end

        it "should use the :controller request parameter when :action is provided" do
          url(:action => "show").should              == "/articles/show"
          url(:action => "show", :id => "15").should == "/articles/show/15"
        end

        it "should use the :action parameter when :id is present" do
          url(:id => "8").should == "/articles/show/8"
        end
      end
      
    end
    
  end
  
end