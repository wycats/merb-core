require File.join(File.dirname(__FILE__), "spec_helper")

describe "Regex-based routes" do

  it "should process a simple regex" do
    prepare_route(%r[^/foos?/(bar|baz)/:id], :controller => "foo", :action => "[1]", :id => ":id")
    route_to("/foo/bar/baz").should have_route(:controller => "foo", :action => "bar", :id => "baz")
    route_to("/foos/baz/bam").should have_route(:controller => "foo", :action => "baz", :id => "bam")
  end

  it "should support inbound user agents" do
    Merb::Router.prepare do |r|
      r.match(%r[^/foo/(.+)], :user_agent => /(MSIE|Gecko)/).
        to(:controller => "foo", :title => "[1]", :action => "show", :agent => ":user_agent[1]")
    end
    route_to("/foo/bar", :user_agent => /MSIE/).should have_route(
      :controller => "foo", :action => "show", :title => "bar", :agent => "MSIE"
    )
  end

end

describe "Routes that are restricted based on incoming params" do

  it "should allow you to restrict routes to POST requests" do
    Merb::Router.prepare do |r|
      r.match("/:controller/create/:id", :method => :post).
        to(:action => "create")
    end
    route_to("/foo/create/12", :method => "post").should have_route(
      :controller => "foo", :action => "create", :id => "12"
    )

    route_to("/foo/create/12", :method => "get").should_not have_route(
      :controller => "foo", :action => "create", :id => "12"
    )
  end

  it "should allow you to restrict routes based on protocol" do
    Merb::Router.prepare do |r|
      r.match(:protocol => "http://").to(:controller => "foo", :action => "bar")
      r.default_routes
    end
    route_to("/foo/bar").should have_route(:controller => "foo", :action => "bar")
    route_to("/boo/hoo", :protocol => "https://").should have_route(:controller => "boo", :action => "hoo")
  end

  it "does not require explicit specifying of params" do
    Merb::Router.prepare do |r|
      r.match!("/fb/:callback_path/:controller/:action")
    end

    route_to("/fb/callybacky/products/search").should have_route(
      :controller => "products", :action => "search", :callback_path => "callybacky"
    )
    route_to("/fb/ping/products/search").should have_route(
      :controller => "products", :action => "search", :callback_path => "ping"
    )
  end

end
