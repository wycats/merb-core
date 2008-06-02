require File.join(File.dirname(__FILE__), "spec_helper")

describe "A route marked as fixatable" do
  predicate_matchers[:allow_fixation] = :allow_fixation?

  it "allows fixation" do
    Merb::Router.prepare do |r|
      r.match("/hello/:action/:id").to(:controller => "foo", :action => "fixoid").fixatable
    end

    matched_route_for("/hello/goodbye/tagging").should allow_fixation
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
