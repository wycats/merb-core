require File.join(File.dirname(__FILE__), "spec_helper")

describe "namespaced resource(s) routes" do

  after :each do
    Merb::Router.named_routes = {}
    Merb::Router.routes = []
  end

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

  it "should match a get to /admin/foo/blogposts to the blogposts controller and index action" do
    Merb::Router.prepare do |r|
      r.namespace :admin do |admin|
        admin.resource :foo do |foo|
          foo.resources :blogposts
        end
      end
    end
    route_to('/admin/foo/blogposts', :method => :get).should have_route(:controller => 'blogposts', :action => 'index', :id => nil)
  end

  it "should match a get to /admin/blogposts/1/foo to the foo controller and the show action" do
    Merb::Router.prepare do |r|
      r.namespace :admin do |admin|
        admin.resources :blogposts do |blogposts|
          blogposts.resource :foo
        end
      end
    end
    route_to('/admin/blogposts/1/foo', :method => :get).should have_route(:controller => 'foo', :action => 'show', :blogpost_id => '1', :id => nil)
  end

end
