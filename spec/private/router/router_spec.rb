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



describe Merb::Router, ".generate", "given a Symbol" do
  before :each do
    Merb::Router.prepare do |r|
      r.match("/elements/").to(:controller => "elements").name(:elements)
    end
  end

  it "searches among named routes" do
    Merb::Router.generate(:elements).should == "/elements/"
  end

  it "raises RuntimeError when named route is not found" do
    lambda { Merb::Router.generate(:mountains) }.should raise_error(RuntimeError, /Named route not found/)
  end
end



describe Merb::Router, ".generate", "given a Hash" do
  before :each do
    Merb::Router.prepare do |r|
      r.match("/elements/").to(:controller => "elements").name(:elements)
    end
  end

  it "uses default routes mapping" do
    Merb::Router.generate({ :controller => "elements", :action => "show", :id => "fire" }).should == "/elements/show/fire"
  end

  it "appends extra parameters to URL" do
    Merb::Router.generate({ :controller => "elements", :action => "search" }, { :q => "water" }).should == "/elements/search?q=water"
  end

  it "uses fallback hash when controller is not available" do
    Merb::Router.generate({ :action => "show", :id => "Olympus" }, {}, { :controller => "mountains" }).should == "/mountains/show/Olympus"
  end

  it "uses fallback hash when action is not available" do
    Merb::Router.generate({ :controller => "mountains", :id => "Olympus" }, {}, { :action => "show" }).should == "/mountains/show/Olympus"
  end

  it "ignores nil parameters" do
    Merb::Router.generate({ :controller => "mountains", :action => nil, :id => "Olympus" }, {}, { :action => "show" }).should == "/mountains/show/Olympus"
  end

  it "respects format parameter" do
    Merb::Router.generate({ :controller => "elements", :action => "show", :id => "fire", :format => :json }).should == "/elements/show/fire.json"
  end
  
  it "respects fragment parameter" do
    Merb::Router.generate({ :controller => "elements", :action => "search", :fragment => :a_fragment }, { :q => "water" }).should == "/elements/search?q=water#a_fragment"
  end
end



describe Merb::Router, ".generate_for_default_route", "given a Hash" do
  before :each do
    Merb::Router.prepare do |r|
      r.match("/elements/").to(:controller => "elements").name(:elements)
    end
  end

  it "uses default routes mapping" do
    Merb::Router.generate_for_default_route({ :controller => "elements", :action => "show", :id => "fire" }, {}).should == "/elements/show/fire"
  end

  it "respects format parameter" do
    Merb::Router.generate({ :controller => "elements", :action => "show", :id => "fire", :format => :json }).should == "/elements/show/fire.json"
  end
  
  it "respects fragment parameter" do
    Merb::Router.generate({ :controller => "elements", :action => "show", :id => "fire", :format => :json, :fragment => :a_fragment }).should == "/elements/show/fire.json#a_fragment"
  end

  it "requires both parameters to be present" do
    lambda {
      Merb::Router.generate_for_default_route({ :controller => "elements", :action => "show", :id => "fire" })
    }.should raise_error(ArgumentError)
  end

  it "uses fallback hash when controller is not available" do
    Merb::Router.generate_for_default_route({ :action => "show", :id => "Olympus" }, { :controller => "mountains" }).should == "/mountains/show/Olympus"
  end

  it "uses fallback hash when action is not available" do
    Merb::Router.generate_for_default_route({ :controller => "mountains", :id => "Olympus" }, { :action => "show" }).should == "/mountains/show/Olympus"
  end

  it "ignores nil parameters" do
    Merb::Router.generate_for_default_route({ :controller => "mountains", :action => nil, :id => "Olympus" }, { :action => "show" }).should == "/mountains/show/Olympus"
  end
end
