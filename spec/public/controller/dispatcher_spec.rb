require File.join(File.dirname(__FILE__), "spec_helper")
require File.join(File.dirname(__FILE__), "controllers", "dispatcher")

include Merb::Test::Fixtures::Controllers

describe Merb::Dispatcher do
  include Merb::Test::Rspec::ControllerMatchers
  include Merb::Test::Rspec::ViewMatchers
  
  def dispatch(url)
    Merb::Dispatcher.handle(request_for(url))
  end

  def request_for(url)
    Merb::Request.new(Rack::MockRequest.env_for(url))
  end

  before(:each) do
    Merb::Config[:exception_details] = true
  end

  describe "with a regular route, " do
    before(:each) do
      Merb::Router.prepare do |r|
        r.default_routes
      end
      @url = "/dispatch_to/index"
    end
  
    it "dispatches to the right controller and action" do
      controller = dispatch(@url)
      controller.body.should == "Dispatched"
    end
    
    it "has the correct status code" do
      controller = dispatch(@url)
      controller.status.should == 200
    end
    
    it "sets the Request#params to include the route params" do
      controller = dispatch(@url)
      controller.request.params.should == 
        {"controller" => "dispatch_to", "action" => "index", 
         "id" => nil, "format" => nil}
    end
    
    it "provides the time for start of request handling via Logger#info" do
      with_level(:info) do
        dispatch(@url)
      end.should include_log("Started request handling")
      
      with_level(:warn) do
        dispatch(@url)
      end.should_not include_log("Started request handling")
    end
    
    it "provides the routed params via Logger#debug" do
      with_level(:debug) do
        dispatch(@url)
      end.should include_log("Routed to:")
      
      with_level(:info) do
        dispatch(@url)
      end.should_not include_log("Routed to:")
    end
    
    it "provides the benchmarks via Logger#info" do
      with_level(:info) do
        dispatch(@url)
      end.should include_log(":after_filters_time")
      
      with_level(:warn) do
        dispatch(@url)
      end.should_not include_log(":after_filters_time")
    end
  end
  
  describe "with a route that redirects" do
    before(:each) do
      Merb::Router.prepare do |r|
        r.match("/redirect/to/foo").redirect("/foo")
        r.default_routes
      end
      @url = "/redirect/to/foo"
      @controller = dispatch(@url)
    end
    
    it "redirects" do
      @controller.body.should =~ %r{You are being <a href="/foo">redirected}
    end
    
    it "reports that it is redirecting via Logger#info" do
      with_level(:info) do
        dispatch(@url)
      end.should include_log("Dispatcher redirecting to: /foo (301)")
      
      with_level(:warn) do
        dispatch(@url)
      end.should_not include_log("Dispatcher redirecting to: /foo (301)")
    end
    
    it "sets the status correctly" do
      @controller.status.should == 301
    end
    
    it "sets the location correctly" do
      @controller.headers["Location"].should == "/foo"
    end
  end
  
  describe "with a route that points to a class that is not a Controller, " do
    before(:each) do
      Merb::Router.prepare do |r|
        r.default_routes
      end
      @url = "/not_a_controller/index"
      @controller = dispatch(@url)
    end
    
    describe "with exception details showing" do
      it "raises a NotFound" do
        @controller.should be_error(Merb::ControllerExceptions::NotFound)
      end
    
      it "returns a 404 status" do
        @controller.status.should == 404
      end
      
      it "returns useful info in the body" do
        @controller.body.should =~
          %r{<h2>Controller 'Merb::Test::Fixtures::Controllers::NotAController' not found.</h2>}
      end
    end
    
    describe "when the action raises an Exception" do
      before(:each) do
        Object.class_eval <<-RUBY
          class Exceptions < Application
            def gone
              "Gone"
            end
          end
        RUBY
      end
      
      after(:each) do
        Object.send(:remove_const, :Exceptions)
      end
      
      before(:each) do
        Merb::Router.prepare do |r|
          r.default_routes
        end
        @url = "/raise_gone/index"
        @controller = dispatch(@url)
      end
      
      it "remembers that the Exception is Gone" do
        @controller.should be_error(Merb::ControllerExceptions::Gone)
      end
      
      it "renders the action Exception#gone" do
        @controller.body.should == "Gone"
      end
      
      it "returns the status 410" do
        @controller.status.should == 410
      end
    end
    
    describe "when the action raises an Exception that has a superclass Exception available" do
      before(:each) do
        Object.class_eval <<-RUBY
          class Exceptions < Application
            def client_error
              "ClientError"
            end
          end
        RUBY
      end
      
      after(:each) do
        Object.send(:remove_const, :Exceptions)
      end
      
      before(:each) do
        Merb::Router.prepare do |r|
          r.default_routes
        end
        @url = "/raise_gone/index"
        @controller = dispatch(@url)
      end
      
      it "renders the Exception from the Exceptions controller" do
        @controller.should be_error(Merb::ControllerExceptions::Gone)
      end
      
      it "renders the action Exceptions#client_error since #gone is not defined" do
        @controller.body.should == "ClientError"
      end
      
      it "returns the status 410 (Gone) even though we rendered #client_error" do
        @controller.status.should == 410
      end
    end
  end
  
  describe "when the action raises an Error that is not a ControllerError" do
    before(:each) do
      Object.class_eval <<-RUBY
        class Exceptions < Application
          def load_error
            "LoadError"
          end
        end
      RUBY
    end
    
    after(:each) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do |r|
        r.default_routes
      end
      @url = "/raise_load_error/index"
      @controller = dispatch(@url)
    end
    
    it "knows that the error is a LoadError" do
      @controller.should be_error(LoadError)
    end
    
    it "renders Exceptions#load_error" do
      @controller.body.should == "LoadError"
    end
    
    it "returns a 500 status code" do
      @controller.status.should == 500
    end
  end

  describe "when the Exception action raises" do
    before(:each) do
      Object.class_eval <<-RUBY
        class Exceptions < Application
          def load_error
            raise StandardError, "Big error"
          end
        end
      RUBY
    end
    
    after(:each) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do |r|
        r.default_routes
      end
      @url = "/raise_load_error/index"
      @controller = dispatch(@url)
    end
    
    it "knows that the error is a StandardError" do
      @controller.should be_error(StandardError)
    end
    
    it "renders the default exception template" do
      @controller.body.should have_xpath("//h1[contains(.,'Standard Error')]")
      @controller.body.should have_xpath("//h2[contains(.,'Big error')]")

      @controller.body.should have_xpath("//h1[contains(.,'Load Error')]")
      @controller.body.should have_xpath("//h2[contains(.,'Big error')]")
    end
    
    it "returns a 500 status code" do
      @controller.status.should == 500
    end
  end


  describe "when the Exception action raises a NotFound" do
    before(:each) do
      Object.class_eval <<-RUBY
        class Exceptions < Application
          def not_found
            raise NotFound, "Somehow, the thing you were looking for was not found."
          end
        end
      RUBY
    end
    
    after(:each) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do |r|
        r.default_routes
      end
      @url = "/page/not/found"
      @controller = dispatch(@url)
    end
    
    it "knows that the error is a NotFound" do
      @controller.should be_error(Merb::ControllerExceptions::NotFound)
    end
    
    it "renders the default exception template" do
      @controller.body.should have_xpath("//h1[contains(.,'Not Found')]")
      @controller.body.should have_xpath("//h2[contains(.,'Somehow, the thing')]")
    end
    
    it "returns a 404 status code" do
      @controller.status.should == 404
    end
  end

  describe "when the Exception action raises the same thing as the original failure" do
    before(:each) do
      Object.class_eval <<-RUBY
        class Exceptions < Application
          def load_error
            raise LoadError, "Something failed here"
          end          
        end
      RUBY
    end
    
    after(:each) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do |r|
        r.default_routes
      end
      @url = "/raise_load_error/index"
      @controller = dispatch(@url)
    end
    
    it "knows that the error is a NotFound" do
      @controller.should be_error(LoadError)
    end
    
    it "renders the default exception template" do
      @controller.body.should have_xpath("//h2[contains(.,'Something failed here')]")
    end
    
    it "returns a 500 status code" do
      @controller.status.should == 500
    end
  end

  describe "when more than one Exceptions methods raises an Error" do
    before(:each) do
      Object.class_eval <<-RUBY
        class Exceptions < Application
          def load_error
            raise StandardError, "StandardError"
          end
          
          def standard_error
            raise Exception, "Exception"
          end
        end
      RUBY
    end
    
    after(:each) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do |r|
        r.default_routes
      end
      @url = "/raise_load_error/index"
      @controller = dispatch(@url)
      @body = @controller.body
    end
    
    it "knows that the error is a NotFound" do
      @controller.should be_error(Exception)
    end
    
    it "renders a list of links to the traces" do
      @body.should have_xpath("//li//a[@href='#exception_0']")
      @body.should have_xpath("//li//a[@href='#exception_1']")
      @body.should have_xpath("//li//a[@href='#exception_2']")
    end
    
    it "renders the default exception template" do
      @body.should have_xpath("//h1[contains(.,'Load Error')]")
      @body.should have_xpath("//h2[contains(.,'In the controller')]")
      @body.should have_xpath("//h1[contains(.,'Standard Error')]")
      @body.should have_xpath("//h2[contains(.,'StandardError')]")
      @body.should have_xpath("//h1[contains(.,'Exception')]")
      @body.should have_xpath("//h2[contains(.,'Exception')]")
    end
    
    it "returns a 500 status code" do
      @controller.status.should == 500
    end
  end
  
end