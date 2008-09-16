require File.join(File.dirname(__FILE__), "spec_helper")

module Merb::Test::Fixtures
  module Controllers
    class FixatableRoutes < Merb::Controller
      
      def fixoid
      end
      
    end
  end
end

describe "A route marked as fixatable" do
  predicate_matchers[:allow_fixation] = :allow_fixation?

  before do
    Merb::Router.prepare do |r|
      r.match("/hello/:action/:id").to(
        :controller => "merb/test/fixtures/controllers/fixatable_routes", 
        :action => "fixoid").fixatable
    end
  end

  it "allows fixation" do
    matched_route_for("/hello/goodbye/tagging").should allow_fixation
  end
  
  it "should store a cookie with the session_id" do
    session_id = Merb::SessionMixin.rand_uuid
    request = fake_request(:request_uri => "/hello/goodbye/tagging", 
      :query_string => "_session_id=#{session_id}")
    controller = ::Merb::Dispatcher.handle(request)
    controller.params["_session_id"].should == session_id
    controller.request.session_cookie_value.should == session_id
  end
end

describe "A route NOT marked as fixatable" do
  predicate_matchers[:allow_fixation] = :allow_fixation?

  it "DOES NOT allow fixation" do
    Merb::Router.prepare do |r|
      r.match("/hello/:action/:id").to(:controller => "foo", :action => "fixoid")
    end

    matched_route_for("/hello/goodbye/tagging").should_not allow_fixation
  end
end
