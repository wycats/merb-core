require File.join(File.dirname(__FILE__), "spec_helper")

describe "namespaced resource(s) routes" do

  it "should match a get to /admin/blogposts to the blogposts controller and index action" do
    Merb::Router.prepare do |r|
      r.namespace :admin do |admin|
        admin.resources :blogposts
      end
    end
    route_to('/admin/blogposts', :method => :get).should have_route(:controller => 'blogposts', :action => 'index', :id => nil)
  end

  it "should match a get to /admin/foo to the foo controller and show action" do
    Merb::Router.prepare do |r|
      r.namespace :admin do |admin|
        admin.resource :foo
      end
    end
    route_to('/admin/foo', :method => :get).should have_route(:controller => 'foo', :action => 'show', :id => nil)
  end

end
