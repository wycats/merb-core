require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

Merb.start :environment => 'test', :log_level => :fatal

class TestController < Merb::Controller
  def get(id = nil); end
  def post(version = nil); end
end

class IDish
  attr_accessor :id
  alias_method :to_param, :id

  def initialize(id)
    @id = id
  end
end

describe Merb::Test::Rspec::RouteMatchers do
  include Merb::Test::RouteHelper

  before(:each) do
    Merb::Router.prepare do |r|
      r.match(%r"/v(\d+\.\d+)", :method => :post).to(:controller => "test_controller", :action => "post", :version => "[1]")
      r.match("/", :method => :get).to(:controller => "test_controller", :action => "get").name(:getter)
      r.match("/", :method => :post).to(:controller => "test_controller", :action => "post")
      r.match("/:id").to(:controller => "test_controller", :action => "get").name(:with_id)
    end
  end

  describe "#route_to" do
    it "should work with the request_to helper" do
      request_to("/", :get).should route_to(TestController, :get)
      request_to("/", :post).should_not route_to(TestController, :get)
    end

    it "should work with the url helper and ParamMatcher" do
      idish = IDish.new(rand(1000).to_s)
      
      request_to(url(:with_id, idish)).should route_to(TestController, :get).with(idish)
    end

    it "should work with a negative ParamMatcher" do
      request_to(url(:with_id, :id => 100)).should_not route_to(TestController, :get).with(:id => 1)
    end

    it "should work with a route containing a regexp" do
      request_to("/v1.2", :post).should route_to(TestController, :post).with(:version => "1.2")
      request_to("/v1.0", :post).should_not route_to(TestController, :post).with(:version => "3.14")
    end
  end

  module Merb::Test::Rspec::RouteMatchers

    describe RouteToMatcher do

      it "should work with snake cased controllers" do
        RouteToMatcher.new(TestController, :get).matches?(:controller => "test_controller", :action => "get").should be_true
      end

      it "should work with camel cased controllers" do
        RouteToMatcher.new(TestController, :get).matches?(:controller => "TestController", :action => "get").should be_true
      end

      it "should work with symbol or string controller name" do
        RouteToMatcher.new(TestController, :get).matches?(:controller => "test_controller", :action => "get").should be_true
        RouteToMatcher.new(TestController, :get).matches?(:controller => :test_controller, :action => :get)
      end

      it "should not pass if the controllers do not match" do
        RouteToMatcher.new(TestController, :get).matches?(:controller => "other_controller", :action => "get").should be_false
      end

      it "should not pass if the actions do not match" do
        RouteToMatcher.new(TestController, :get).matches?(:controller => "test_controller", :action => "post").should be_false
      end

      it "should not pass if the parameters do not the ParameterMatcher" do
        route_matcher = RouteToMatcher.new(TestController, :get)
        route_matcher.with(:id => "123")

        route_matcher.matches?(:controller => "test_case", :action => "get", :id => "456").should be_false
      end

      describe "#with" do
        it "should add a ParameterMatcher" do
          ParameterMatcher.should_receive(:new).with(:id => "123")

          route_matcher = RouteToMatcher.new(TestController, :get)
          route_matcher.with(:id => "123")
        end

        it "should work with an empty expectation" do
          ParameterMatcher.new({}).matches?(:param => "abc").should be_false
        end
      end

      describe "#failure_message" do
        it "should include the expected controller and action" do
          matcher = RouteToMatcher.new(TestController, :any_action)
          matcher.matches?(:controller => "target_controller", :action => "target_action")
          matcher.failure_message.should include("TestController#any_action")
        end

        it "should include the target controller and action in camel case" do
          matcher = RouteToMatcher.new(TestController, :any_action)
          matcher.matches?(:controller => "target_controller", :action => "target_action")
          matcher.failure_message.should include("TargetController#target_action")
        end

        it "should include the expected parameters" do
          expected_parameters = {:id => '123', :page => '2'}
          matcher = RouteToMatcher.new(TestController, :any_action)
          matcher.with(expected_parameters)
          matcher.matches?(:controller => "target_controller", :action => "target_action")
          matcher.failure_message.should include(expected_parameters.inspect)
        end

        it "should include the actual paramters" do
          expected_parameters, actual_parameters = {:id => '123', :page => '2'}, {:id => '2', :page => '321'}
          matcher = RouteToMatcher.new(TestController, :any_action)
          matcher.with(expected_parameters)
          matcher.matches?(actual_parameters.merge(:controller => "test_controller", :action => "any_action"))
          matcher.failure_message.should include(actual_parameters.inspect)
        end
      end

      describe "#negative_failure_message" do
        it "should include the expected controller and action" do
          RouteToMatcher.new(TestController, :any_action).negative_failure_message.should include("TestController#any_action")
        end
      end
    end

    describe ParameterMatcher do
      it "should work with a Hash as the parameter argument" do
        ParameterMatcher.new(:param => "abc").matches?(:param => "abc").should be_true
      end

      it "should work with an object as the parameter argument" do
        ParameterMatcher.new(IDish.new(1234)).matches?(:id => 1234).should be_true
      end

      describe "#failure_message" do
        it "should include the expected parameters hash" do
          parameter_hash = {:parent_id => "123", :child_id => "abc"}
          ParameterMatcher.new(parameter_hash).failure_message.should include(parameter_hash.inspect)
        end

        it "should include the actual parameters hash" do
          parameter_hash = {:parent_id => "123", :child_id => "abc"}
          matcher = ParameterMatcher.new(:id => 123)
          matcher.matches?(parameter_hash)
          matcher.failure_message.should include(parameter_hash.inspect)
        end
      end

      describe "#negative_failure_message" do
        it "should include the expected parameters hash" do
          parameter_hash = {:parent_id => "123", :child_id => "abc"}
          ParameterMatcher.new(parameter_hash).negative_failure_message.should include(parameter_hash.inspect)
        end
      end
    end
  end
end
