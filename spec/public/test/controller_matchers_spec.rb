require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

Merb.start :environment => 'test', :log_level => :fatal

class TestController < Merb::Controller
  attr_accessor :redirect_to
  def redirect_action; redirect(@redirect_to || "/"); end
  def success_action; end
  def missing_action; render("i can has errorz", :status => 404); end

  def redirect_with_message_action
    redirect(@redirect_to, :message => "okey dookey")
  end
end

describe Merb::Test::Rspec::ControllerMatchers do
  include Merb::Test::ControllerHelper
  before(:each) do
    Merb::Router.prepare do |r|
      r.match("/redirect").to(:controller => "test_controller", :action => "redirect_action")
      r.match("/success").to(:controller => "test_controller", :action => "success_action")
      r.match("/missing").to(:controller => "test_controller", :action => "missing_action")
    end
  end
  
  describe "#redirect" do
    it "should work with the result of a dispatch_to helper call" do
      dispatch_to(TestController, :redirect_action).should redirect
    end
    
    it "should work with the result of a get helper call" do
      get("/redirect").should redirect
    end
    
    it "should work with a redirection code" do
      dispatch_to(TestController, :redirect_action).status.should redirect
    end
  end
  
  describe "#redirect_to" do
    it "should work with the result of a dispatch_to helper call" do
      dispatch_to(TestController, :redirect_action).should redirect_to("/")
      dispatch_to(TestController, :redirect_action){ |controller| controller.redirect_to = "http://example.com/" }.should redirect_to("http://example.com/")
    end
    
    it "should work with the result of a get helper call" do
      get("/redirect"){|controller| controller.redirect_to = "http://example.com/" }.should redirect_to("http://example.com/")
    end

    it 'takes :message option' do
      dispatch_to(TestController, :redirect_with_message_action) { |controller|
        controller.redirect_to = "http://example.com/"
      }.should redirect_to("http://example.com/", :message => "okey dookey")
    end
  end
  
  describe "#respond_successfully" do
    it "should work with the result of a dispatch_to helper call" do
      dispatch_to(TestController, :success_action).should respond_successfully
    end
    
    it "should work with the result of a get helper call" do
      get("/success").should respond_successfully
    end
    
    it "should work with a redirection code" do
      dispatch_to(TestController, :success_action).status.should be_successful
    end
  end
  
  describe "#be_missing" do
    it "should work with the result of a dispatch_to helper call" do
      dispatch_to(TestController, :missing_action).should be_missing
    end
    
    it "should work with the result of a get helper call" do
      get("/missing").should be_client_error
    end
    
    it "should work with a redirection code" do
      dispatch_to(TestController, :missing_action).status.should be_missing
    end
  end
end

module Merb::Test::Rspec
  module ControllerMatchers
    class RedirectableTarget
      attr_accessor :status, :headers
      def initialize; @headers = {}; end
    end
    
    describe BeRedirect do
      before(:each) do
        @target = RedirectableTarget.new
      end
      
      it "should match a 301 'Moved Permanently' redirect code" do
        BeRedirect.new.matches?(301).should be_true
      end
      
      it "should match a 302 'Found' redirect code" do
        BeRedirect.new.matches?(302).should be_true
      end
      
      it "should match a 303 'See Other' redirect code" do
        BeRedirect.new.matches?(303).should be_true
      end
      
      it "should match a 304 'Not Modified' redirect code" do
        BeRedirect.new.matches?(304).should be_true
      end
      
      it "should match a 307 'Temporary Redirect' redirect code" do
        BeRedirect.new.matches?(307).should be_true
      end
      
      it "should match a target with a valid redirect code" do
        @target.status = 301
        
        BeRedirect.new.matches?(@target).should be_true
      end
      
      it "should not match a target with an unused redirect code" do
        @target.status = 399
        
        BeRedirect.new.matches?(@target).should_not be_true
      end
      
      it "should not match a target with a non redirect code" do
        @target.status = 200
        
        BeRedirect.new.matches?(@target).should_not be_true
      end
      
      describe "#failure_message" do
        it "should be 'expected to redirect' when the target is a status code" do
          matcher = BeRedirect.new
          matcher.matches?(200)
          matcher.failure_message.should == "expected to redirect"
        end
        
        it "should be 'expected Foo#bar to redirect' when the target's controller is Foo and action is bar" do
          matcher = BeRedirect.new
          @target.stub!(:controller_name).and_return :Foo
          @target.stub!(:action_name).and_return :bar
          matcher.matches?(@target)
          matcher.failure_message.should == "expected Foo#bar to redirect"
        end
      end
      
      describe "#negative_failure_message" do
        it "should be 'expected not to redirect' when the target is a status code" do
          matcher = BeRedirect.new
          matcher.matches?(200)
          matcher.negative_failure_message.should == "expected not to redirect"
        end
        
        it "should be 'expected Foo#bar to redirect' when the target's controller is Foo and action is bar" do
          matcher = BeRedirect.new
          @target.stub!(:controller_name).and_return :Foo
          @target.stub!(:action_name).and_return :bar
          matcher.matches?(@target)
          matcher.negative_failure_message.should == "expected Foo#bar not to redirect"
        end
      end
    end
    
    describe RedirectTo do
      before(:each) do
        @target = RedirectableTarget.new
      end
      
      it "should match a target if the status code is 300 level and the locations match" do
        @target.status = 301
        @target.headers['Location'] = "http://example.com/"
        
        RedirectTo.new("http://example.com/").matches?(@target).should be_true
      end
      
      it "should not match a target if the status code is not 300 level but the locations match" do
        @target.status = 404
        @target.headers['Location'] = "http://example.com/"
        
        RedirectTo.new("http://example.com/").matches?(@target).should_not be_true
      end
      
      it "should not match a target if the status code is 300 level but the locations do not match" do
        @target.status = 301
        @target.headers['Location'] = "http://merbivore.com/"
        
        RedirectTo.new("http://example.com/").matches?(@target).should_not be_true
      end
      
      describe "#failure_message" do
        it "should be 'expected Foo#bar to redirect to <http://expected.com/>, but was <http://target.com/>' when the expected url is http://expected.com/ and the target url is http://target.com/" do
          @target.stub!(:controller_name).and_return :Foo
          @target.stub!(:action_name).and_return :bar
          @target.status = 301
          @target.headers['Location'] = "http://target.com/"
          matcher = RedirectTo.new("http://expected.com/")
          matcher.matches?(@target)
          matcher.failure_message.should == "expected Foo#bar to redirect to <http://expected.com/>, but was <http://target.com/>"
        end
        
        it "should be 'expected Foo#bar to redirect, but there was no redirection' when the target is not redirected" do
          @target.stub!(:controller_name).and_return :Foo
          @target.stub!(:action_name).and_return :bar
          @target.status = 200
          @target.headers['Location'] = "http://target.com/"
          matcher = RedirectTo.new("http://expected.com/")
          matcher.matches?(@target)
          matcher.failure_message.should == "expected Foo#bar to redirect to <http://expected.com/>, but there was no redirection"
        end
      end
      
      describe "#negative_failure_message" do
        it "should be 'expected Foo#bar not to redirect to <http://expected.com/>, but it did anyways" do
          @target.stub!(:controller_name).and_return :Foo
          @target.stub!(:action_name).and_return :bar
          @target.status = 200
          @target.headers['Location'] = "http://target.com/"
          matcher = RedirectTo.new("http://expected.com/")
          matcher.matches?(@target)
          matcher.negative_failure_message.should == "expected Foo#bar not to redirect to <http://expected.com/>, but did anyway"
        end
      end
    end
    
    describe BeSuccess do
      before(:each) do
        @target = RedirectableTarget.new
      end
      
      it "should match a target with a 200 'OK' status code" do
        BeSuccess.new.matches?(200).should be_true
      end
      
      it "should match a target with a 201 'Created' status code" do
        BeSuccess.new.matches?(201).should be_true
      end
      
      it "should match a target with a 202 'Accepted' status code" do
        BeSuccess.new.matches?(202).should be_true
      end
      
      it "should match a target with a 203 'Non-Authoritative Information' status code" do
        BeSuccess.new.matches?(203).should be_true
      end
      
      it "should match a target with a 204 'No Content' status code" do
        BeSuccess.new.matches?(204).should be_true
      end
      
      it "should match a target with a 205 'Reset Content' status code" do
        BeSuccess.new.matches?(205).should be_true
      end
      
      it "should match a target with a 206 'Partial Content' status code" do
        BeSuccess.new.matches?(206).should be_true
      end
      
      it "should match a target with a 207 'Multi-Status' status code" do
        BeSuccess.new.matches?(207).should be_true
      end
      
      it "should not match a target with an unused 200 level status code" do
        BeSuccess.new.matches?(299).should_not be_true
      end
      
      it "should not match a target with a non 200 level status code" do
        BeSuccess.new.matches?(301).should_not be_true
      end
      
      describe "#failure_message" do
        it "should be 'expected to be successful but was 300' when the target is status code 300" do
          matcher = BeSuccess.new
          matcher.matches?(300)
          matcher.failure_message.should == "expected to be successful but was 300"
        end
        
        it "should be 'expected Foo#bar to be successful but was 404' when the target is controller-ish" do
          @target.stub!(:controller_name).and_return :Foo
          @target.stub!(:action_name).and_return :bar
          @target.status = 404
          matcher = BeSuccess.new
          matcher.matches?(@target)
          matcher.failure_message.should == "expected Foo#bar to be successful but was 404"
        end
      end
      
      describe "#negative_failure_message" do
        it "should be 'expected not to be successful but it was' when the target is a 200 status code" do
          matcher = BeSuccess.new
          matcher.matches?(200)
          matcher.negative_failure_message.should == "expected not to be successful but it was 200"
        end
        
        it "should be 'expected Foo#bar not to be successful but it was 200' when the target is controller-ish" do
          @target.stub!(:controller_name).and_return :Foo
          @target.stub!(:action_name).and_return :bar
          @target.status = 200
          matcher = BeSuccess.new
          matcher.matches?(@target)
          matcher.negative_failure_message.should == "expected Foo#bar not to be successful but it was 200"
        end
      end
    end
    
    describe BeMissing do
      before(:each) do
        @target = RedirectableTarget.new
      end
      
      it "should match a 400 'Bad Request'" do
        BeMissing.new.matches?(400).should be_true
      end
      
      it "should match a 401 'Unauthorized'" do
        BeMissing.new.matches?(401).should be_true
      end
      
      it "should match a 403 'Forbidden'" do
        BeMissing.new.matches?(403).should be_true
      end
      
      it "should match a 404 'Not Found'" do
        BeMissing.new.matches?(404).should be_true
      end
      
      it "should match a 409 'Conflict'" do
        BeMissing.new.matches?(409).should be_true
      end
      
      it "should match a target with a valid client side error code" do
        @target.status = 404
        
        BeMissing.new.matches?(@target).should be_true
      end
      
      it "should not match a target with an unused client side error code" do
        @target.status = 499
        
        BeMissing.new.matches?(@target).should_not be_true
      end
      
      it "should not match a target with a non client side error code" do
        @target.status = 200
        
        BeMissing.new.matches?(@target).should_not be_true
      end
      
      describe "#failure_message" do
        it "should be 'expected to be missing but was 300' when the target is status code 300" do
          matcher = BeMissing.new
          matcher.matches?(300)
          matcher.failure_message.should == "expected to be missing but was 300"
        end
        
        it "should be 'expected Foo#bar to be successful but was 301' when the target is controller-ish" do
          @target.stub!(:controller_name).and_return :Foo
          @target.stub!(:action_name).and_return :bar
          @target.status = 301
          matcher = BeMissing.new
          matcher.matches?(@target)
          matcher.failure_message.should == "expected Foo#bar to be missing but was 301"
        end
      end
      
      describe "#negative_failure_message" do
        it "should be 'expected not to be successful but it was' when the target is a 400 status code" do
          matcher = BeMissing.new
          matcher.matches?(400)
          matcher.negative_failure_message.should == "expected not to be missing but it was 400"
        end
        
        it "should be 'expected Foo#bar not to be missing but it was 404' when the target is controller-ish" do
          @target.stub!(:controller_name).and_return :Foo
          @target.stub!(:action_name).and_return :bar
          @target.status = 404
          matcher = BeMissing.new
          matcher.matches?(@target)
          matcher.negative_failure_message.should == "expected Foo#bar not to be missing but it was 404"
        end
      end
    end

    describe Provide do
      class TestController < Merb::Controller
        provides :xml
      end

      it 'should match for formats a controller class provides' do
        Provide.new( :xml ).matches?( TestController ).should be_true
      end

      it 'should match for formats a controller instance provides' do
        t = TestController.new( fake_request )
        Provide.new( :xml ).matches?( t ).should be_true
      end

      it 'should not match for formats a controller class does not provide' do
        Provide.new( :yaml ).matches?( TestController ).should be_false
      end

      it 'should not match for formats a controller instance does not provide' do
        t = TestController.new( fake_request )
        Provide.new( :yaml ).matches?( t ).should be_false
      end
    end
  end
end
