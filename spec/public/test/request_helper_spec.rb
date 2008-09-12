require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

Merb.start :environment => 'test', :log_level => :fatal

Dir[File.join(File.dirname(__FILE__), "controllers/**/*.rb")].each do |f|
  require f
end

describe Merb::Test::RequestHelper do
  
  describe Merb::Test::RequestHelper::CookieJar do
    
    it "should update its values from a request object" do
      cookie_jar = Merb::Test::RequestHelper::CookieJar.new
      cookie_jar.should be_empty
      request = fake_request
      request.cookies[:foo] = "bar+baz" # escaped by default
      cookie_jar.update_from_request request
      cookie_jar[:foo].should == 'bar baz'
    end
    
  end  
  
  describe "#dispatch_to" do

    before(:all) do
      @controller_klass = Merb::Test::DispatchController
    end

    it "should dispatch to the given controller and action" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:index)

      dispatch_to(@controller_klass, :index)
    end

    it "should dispatch to the given controller and action with params" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:show)

      controller = dispatch_to(@controller_klass, :show, :name => "Fred")
      controller.params[:name].should == "Fred"
    end

    it "should dispatch to the given controller and action with the query string merged into the params" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:show)
      controller = dispatch_to(@controller_klass, :show, {:name => "Fred"}, {'QUERY_STRING' => "last_name=Jones&age=42"} )
      
      controller.params[:name].should == "Fred"
      controller.params[:last_name].should == "Jones"
      controller.params[:age].should == "42"   
    end

    it "should not hit the router to match its route" do
      Merb::Router.should_not_receive(:match)
      dispatch_to(@controller_klass, :index)
    end
    
    it "merges :controller into params" do
      controller = dispatch_to(@controller_klass, :show, :name => "Fred")
      
      controller.params[:controller].should == @controller_klass.name.to_const_path
    end
    
    it "merges :action into params" do
      controller = dispatch_to(@controller_klass, :show, :name => "Fred")
      
      controller.params[:action].should == "show"
    end
  end
  
  describe "#dispatch_with_basic_authentication_to" do

    before(:all) do
      @controller_klass = Merb::Test::DispatchController
    end

    it "should dispatch to the given controller and action" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:index)

      dispatch_with_basic_authentication_to(@controller_klass, :index, "Fred", "secret")
    end

    it "should dispatch to the given controller and action with authentication token" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:show)

      controller = dispatch_with_basic_authentication_to(@controller_klass, :show, "Fred", "secret")

      controller.request.env["X_HTTP_AUTHORIZATION"].should == "Basic #{Base64.encode64("Fred:secret")}"
    end
    
    it "should dispatch to the given controller and action with authentication token and params" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:show)

      controller = dispatch_with_basic_authentication_to(@controller_klass, :show, "Fred", "secret", :name => "Fred")

      controller.request.env["X_HTTP_AUTHORIZATION"].should == "Basic #{Base64.encode64("Fred:secret")}"
      controller.params[:name].should == "Fred"
    end

    it "should not hit the router to match its route" do
      Merb::Router.should_not_receive(:match)
      dispatch_with_basic_authentication_to(@controller_klass, :index, "Fred", "secret")
    end
  end

  describe "#get" do
    before(:each) do 
      Merb::Router.prepare do |r| 
        r.resources :spec_helper_controller
        r.match("/:controller/:action/:custom").to(:controller => ":controller") 
      end
    end

    it "should perform the index action when used with a get" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:index)
      get("/spec_helper_controller")  
    end

    it "should perform the index action and have params available" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:index)
      controller = get("/spec_helper_controller", :name => "Harry")
      controller.params[:name].should == "Harry"    
    end
    
    it "should perform the index action and have params available from the query string" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:index)
      controller = get("/spec_helper_controller?last_name=Oswald&age=25", :name => "Harry")
      controller.params[:name].should == "Harry"
      controller.params[:last_name].should == "Oswald"
      controller.params[:age].should == "25"
    end

    it "should evaluate in the context of the controller in the block" do
      get("/spec_helper_controller") do |controller|
        controller.class.should == SpecHelperController
      end    
    end

    it "should allow for custom router params" do
      controller = get("/spec_helper_controller/index/my_custom_stuff")
      controller.params[:custom].should == "my_custom_stuff"    
    end   

    it "should get the show action" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:show)
      controller = get("/spec_helper_controller/my_id")
      controller.params[:id].should == "my_id"    
    end
  end

  describe "#post" do
    before(:each) do
      Merb::Router.prepare do |r|
        r.resources :spec_helper_controller
      end
    end

    it "should post to the create action" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:create)
      post("/spec_helper_controller")
    end

    it "should post to the create action with params" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:create)
      controller = post("/spec_helper_controller", :name => "Harry")
      controller.params[:name].should == "Harry"
    end
  end

  describe "#put" do
    before(:each) do
      Merb::Router.prepare do |r|
        r.resources :spec_helper_controller
      end
    end
    it "should put to the update action" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:update)
      put("/spec_helper_controller/1")
    end

    it "should put to the update action with params" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:update)
      controller = put("/spec_helper_controller/my_id", :name => "Harry")
      controller.params[:name].should == "Harry"
      controller.params[:id].should   == "my_id"
    end
  end

  describe "#delete" do
    before(:each) do
      Merb::Router.prepare do |r|
        r.resources :spec_helper_controller
      end
    end
    it "should put to the update action" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:destroy)
      delete("/spec_helper_controller/1")
    end

    it "should put to the update action with params" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:destroy)
      controller = delete("/spec_helper_controller/my_id", :name => "Harry")
      controller.params[:name].should == "Harry"
      controller.params[:id].should   == "my_id"
    end
  end
  
  describe "#request" do
    before(:each) do 
      Merb::Router.prepare do |r| 
        r.namespace :namespaced do |namespaced|
          namespaced.resources :spec_helper_controller
        end
      end
    end
    
    it "should get namespaced index action" do
      Merb::Test::ControllerAssertionMock.should_receive(:called).with(:index)
      controller = request("/namespaced/spec_helper_controller")
      controller.class.should == Namespaced::SpecHelperController
    end
  end
  
end

module Merb::Test::RequestHelper
  describe FakeRequest, ".new(env = {}, req = StringIO.new)" do
    it "should create request with default enviroment, minus rack.input" do
      @mock = FakeRequest.new
      @mock.env.except('rack.input').should == FakeRequest::DEFAULT_ENV
    end

    it "should override default env values passed in HTTP format" do
      @mock = FakeRequest.new('HTTP_ACCEPT' => 'nothing')
      @mock.env['HTTP_ACCEPT'].should == 'nothing'
    end

    it "should override default env values passed in symbol format" do
      @mock = FakeRequest.new(:http_accept => 'nothing')
      @mock.env['HTTP_ACCEPT'].should == 'nothing'
    end

    it "should set rack input to an empty StringIO" do
      @mock = FakeRequest.new
      @mock.env['rack.input'].should be_kind_of(StringIO)
      @mock.env['rack.input'].read.should == ''
    end
  end
end