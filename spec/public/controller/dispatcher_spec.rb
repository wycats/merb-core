require File.join(File.dirname(__FILE__), "spec_helper")
require File.join(File.dirname(__FILE__), "controllers", "dispatcher")

include Merb::Test::Fixtures::Controllers

describe Merb::Dispatcher do

  def with_level(level)
    Merb.logger = Merb::Logger.new(StringIO.new, level)
    yield
    Merb.logger
  end

  describe "with a regular route, " do
    before(:each) do
      Merb::Router.prepare do |r|
        r.default_routes
      end
      @env = Rack::MockRequest.env_for("/dispatch_to/index")
    end
  
    it "dispatches to the right controller and action" do
      controller = Merb::Dispatcher.handle(@env)
      controller.body.should == "Dispatched"
    end
    
    it "sets the Request#params to include the route params" do
      controller = Merb::Dispatcher.handle(@env)
      controller.request.params.should == 
        {"controller" => "dispatch_to", "action" => "index", 
         "id" => nil, "format" => nil}
    end
    
    it "provides the time for start of request handling via Logger#info" do
      with_level(:info) do
        Merb::Dispatcher.handle(@env)
      end.should include_log("Started request handling")
      
      with_level(:warn) do
        Merb::Dispatcher.handle(@env)
      end.should_not include_log("Started request handling")
    end
    
    it "provides the routed params via Logger#debug" do
      with_level(:debug) do
        Merb::Dispatcher.handle(@env)
      end.should include_log("Routed to:")
      
      with_level(:info) do
        Merb::Dispatcher.handle(@env)
      end.should_not include_log("Routed to:")
    end
    
    it "provides the benchmarks via Logger#info" do
      with_level(:info) do
        Merb::Dispatcher.handle(@env)
      end.should include_log(":after_filters_time")
      
      with_level(:warn) do
        Merb::Dispatcher.handle(@env)
      end.should_not include_log(":after_filters_time")
    end
  end
  
  describe "with a route that redirects" do
    before(:each) do
      Merb::Router.prepare do |r|
        r.match("/redirect/to/foo").redirect("/foo")
        r.default_routes
      end
      @env = Rack::MockRequest.env_for("/redirect/to/foo")
      @controller = Merb::Dispatcher.handle(@env)
    end
    
    it "redirects" do
      @controller.body.should =~ %r{You are being <a href="/foo">redirected}
    end
    
    it "reports that it is redirecting via Logger#info" do
      with_level(:info) do
        Merb::Dispatcher.handle(@env)
      end.should include_log("Dispatcher redirecting to: /foo")
      
      with_level(:warn) do
        Merb::Dispatcher.handle(@env)
      end.should_not include_log("Dispatcher redirecting to: /foo")
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
      @env = Rack::MockRequest.env_for("/not_a_controller/index")
      @controller = Merb::Dispatcher.handle(@env)
    end
    
    describe "with exception details showing" do
      before(:each) do
        Merb::Config[:exception_details] = true
      end
    
      it "raises a NotFound" do
        @controller.request.exception_details[:exception].
          should be_kind_of(Merb::ControllerExceptions::NotFound)
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
      before(:all) do
        Object.class_eval <<-RUBY
          class Exceptions < Merb::Controller
            def gone
              "Gone"
            end
          end
        RUBY
      end
      
      after(:all) do
        Object.send(:remove_const, :Exceptions)
      end
      
      before(:each) do
        Merb::Router.prepare do |r|
          r.default_routes
        end
        @env = Rack::MockRequest.env_for("/raise_gone/index")
        @controller = Merb::Dispatcher.handle(@env)
      end
      
      it "remembers that the Exception is Gone" do
        @controller.request.exception_details[:exception].
          should be_kind_of(Merb::ControllerExceptions::Gone)
      end
      
      it "renders the action Exception#gone" do
        @controller.body.should == "Gone"
      end
      
      it "returns the status 410" do
        @controller.status.should == 410
      end
    end
    
    describe "when the action raises an Exception that has a superclass Exception available" do
      before(:all) do
        Object.class_eval <<-RUBY
          class Exceptions < Merb::Controller
            def client_error
              "ClientError"
            end
          end
        RUBY
      end
      
      after(:all) do
        Object.send(:remove_const, :Exceptions)
      end
      
      before(:each) do
        Merb::Router.prepare do |r|
          r.default_routes
        end
        @env = Rack::MockRequest.env_for("/raise_gone/index")
        @controller = Merb::Dispatcher.handle(@env)
      end
      
      it "renders the Exception from the Exceptions controller" do
        @controller.request.exception_details[:exception].
          should be_kind_of(Merb::ControllerExceptions::Gone)
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
    before(:all) do
      Object.class_eval <<-RUBY
        class Exceptions < Merb::Controller
          def load_error
            "LoadError"
          end
        end
      RUBY
    end
    
    after(:all) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do |r|
        r.default_routes
      end
      @env = Rack::MockRequest.env_for("/raise_load_error/index")
      @controller = Merb::Dispatcher.handle(@env)
    end
    
    it "knows that the error is a LoadError" do
      @controller.request.exception_details[:exception].
        should be_kind_of(LoadError)
    end
    
    it "renders Exceptions#load_error" do
      @controller.body.should == "LoadError"
    end
    
    it "returns a 500 status code" do
      @controller.status.should == 500
    end
  end

  describe "when the Exception action raises" do
    before(:all) do
      Object.class_eval <<-RUBY
        class Exceptions < Merb::Controller
          def load_error
            raise StandardError, "Big error"
          end
        end
      RUBY
    end
    
    after(:all) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do |r|
        r.default_routes
      end
      @env = Rack::MockRequest.env_for("/raise_load_error/index")
      @controller = Merb::Dispatcher.handle(@env)
    end
    
    it "knows that the error is a StandardError" do
      @controller.request.exception_details[:exception].
        should be_kind_of(StandardError)
    end
    
    it "renders the default exception template" do
      @controller.body.should =~ /<h1>Standard Error/
      @controller.body.should =~ /<h2>Big error/
    end
    
    it "returns a 500 status code" do
      @controller.status.should == 500
    end
  end


  describe "when the Exception action raises a NotFound" do
    before(:all) do
      Object.class_eval <<-RUBY
        class Exceptions < Merb::Controller
          def not_found
            raise NotFound, "Somehow, the thing you were looking for was not found."
          end
        end
      RUBY
    end
    
    after(:all) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do |r|
        r.default_routes
      end
      @env = Rack::MockRequest.env_for("/page/not/found")
      @controller = Merb::Dispatcher.handle(@env)
    end
    
    it "knows that the error is a NotFound" do
      @controller.request.exception_details[:exception].
        should be_kind_of(Merb::ControllerExceptions::NotFound)
    end
    
    it "renders the default exception template" do
      @controller.body.should =~ /<h1>Not Found/
      @controller.body.should =~ /<h2>Somehow, the thing/
    end
    
    it "returns a 404 status code" do
      @controller.status.should == 404
    end
  end

  describe "when the Exception action raises the same thing as the original failure" do
    before(:all) do
      Object.class_eval <<-RUBY
        class Exceptions < Merb::Controller
          def load_error
            raise LoadError, "Something failed here"
          end          
        end
      RUBY
    end
    
    after(:all) do
      Object.send(:remove_const, :Exceptions)
    end
    
    before(:each) do
      Merb::Router.prepare do |r|
        r.default_routes
      end
      @env = Rack::MockRequest.env_for("/raise_load_error/index")
      @controller = Merb::Dispatcher.handle(@env)
    end
    
    it "knows that the error is a NotFound" do
      @controller.request.exception_details[:exception].
        should be_kind_of(LoadError)
    end
    
    it "renders the default exception template" do
      @controller.body.should =~ /Something failed here/
    end
    
    it "returns a 500 status code" do
      @controller.status.should == 500
    end
  end

  
end