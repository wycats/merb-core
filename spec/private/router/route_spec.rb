require File.dirname(__FILE__) + '/../../spec_helper'

describe Merb::Router, "initially" do
  it "has empty routes array" do
    Merb::Router.routes.should be_empty
  end

  it "has empty named routes" do
    Merb::Router.named_routes.should be_empty
  end

  it "stores named routes in a Hash" do
    Merb::Router.named_routes.should be_kind_of(Hash)
  end

  it "has no .match method" do
    Merb::Router.should_not respond_to(:match)
  end
end



describe Merb::Router, ".prepare" do
  before :each do
    Merb::Router.routes = []
    # sanity check
  end

  it "adds prepared routes to existing" do
    Merb::Router.prepare do |r|
      r.match("/").to(:controller => "home")
    end

    Merb::Router.routes.should_not be_empty
  end

  it "(re-)compiles routes" do
    Merb::Router.should_receive(:compile)

    Merb::Router.prepare do |r|
      r.match("/").to(:controller => "home")
    end
  end

  it "defines match method" do
    Merb::Router.prepare do |r|
      r.match("/").to(:controller => "home")
    end

    Merb::Router.should respond_to(:match)
  end
end



describe Merb::Router, ".append" do
  before :each do
    Merb::Router.prepare do |r|
      r.match("/").to(:controller => "home")
    end
  end

  it "appends routes to existing" do
    Merb::Router.append do |r|
      r.match("/append").to(:controller => "appended_by_router").name(:appended)
    end

    Merb::Router.named_routes[:appended].index.should == 0
  end
end



describe Merb::Router, ".prepend" do
  before :each do
    Merb::Router.prepare do |r|
      r.match("/").to(:controller => "home")
    end
  end

  it "prepends routes to existing" do
    Merb::Router.prepend do |r|
      r.match("/prepend").to(:controller => "prepended_by_router").name(:prepended)
    end

    Merb::Router.named_routes[:appended].index.should == 0
  end
end
