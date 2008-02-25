require File.join(File.dirname(__FILE__), "spec_helper")
describe "namespaced resource(s) routes" do

  after :each do
    Merb::Router.named_routes = {}
    Merb::Router.routes = []
  end

  it "should match a get to /admin/blogposts without setting namespace" do
    Merb::Router.prepare do |r|
      r.match('/admin') do |admin|
        admin.resources :blogposts
      end
    end
    route_to('/admin/blogposts', :method => :get).should have_route(:controller => 'blogposts', :action => 'index', :id => nil, :namespace=>nil)
  end

  it "should match a get to /admin/blogposts setting namespace manually" do
    Merb::Router.prepare do |r|
      r.match('/admin').to(:namespace => "my_admin") do |admin|
        admin.resources :blogposts
      end
    end
    route_to('/admin/blogposts', :method => :get).should have_route(:controller => 'blogposts', :action => 'index', :id => nil, :namespace=>"my_admin")
  end

  it "should match a get to /admin/blogposts to the blogposts controller and index action" do
    Merb::Router.prepare do |r|
      r.namespace :admin do |admin|
        admin.resources :blogposts
      end
    end
    route_to('/admin/blogposts', :method => :get).should have_route(:controller => 'blogposts', :action => 'index', :id => nil, :namespace => 'admin')
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
    route_to('/admin/foo/blogposts', :method => :get).should have_route(:controller => 'blogposts', :action => 'index', :id => nil, :namespace => 'admin')
  end

  it "should match a get to /admin/blogposts/1/foo to the foo controller and the show action" do
    Merb::Router.prepare do |r|
      r.namespace :admin do |admin|
        admin.resources :blogposts do |blogposts|
          blogposts.resource :foo
        end
      end
    end
    route_to('/admin/blogposts/1/foo', :method => :get).should have_route(:controller => 'foo', :action => 'show', :blogpost_id => '1', :id => nil, :namespace => "admin")
  end

  it "should match a get to /blogposts to the blogposts controller when namespace is passed in to resources" do
    Merb::Router.prepare do |r|
      r.resources :blogposts, :namespace => "admin"
    end
    route_to("/blogposts", :method =>:get).should have_route(:controller => 'blogposts', :action => 'index', :id => nil, :namespace => "admin")
  end

  it "should match a get to /blogposts/1/foo to the foo controller when namespace is passed in to resources as an option" do
    Merb::Router.prepare do |r|
      r.resources :blogposts, :namespace => "admin" do |blogposts|
        blogposts.resource :foo, :namespace => "admin"
      end
    end
    route_to("/blogposts", :method =>:get).should have_route(:controller => 'blogposts', :action => 'index', :id => nil, :namespace => "admin")
    route_to("/blogposts/1/foo", :method =>:get).should have_route(:controller => 'foo', :action => 'show', :blogpost_id => '1', :namespace => "admin")
  end
  
  it "should match a get to /blogposts/1/foo to the foo controller without a namespace" do
    Merb::Router.prepare do |r|
      r.resources :blogposts, :namespace => "admin" do |blogposts|
        blogposts.resource :foo
      end
    end
    route_to("/blogposts/1/foo", :method =>:get).should have_route(:controller => 'foo', :action => 'show', :blogpost_id => '1', :namespace => nil)
  end
  
  it "should match a get to /my_admin/blogposts to the blogposts controller with a custom patch setting" do
    Merb::Router.prepare do |r|
      r.namespace(:admin, :path=>"my_admin") do |admin|
        admin.resources :blogposts
      end
    end
    route_to('/my_admin/blogposts', :method => :get).should have_route(:controller => 'blogposts', :action => 'index', :id => nil, :namespace => 'admin')
  end

  it "should match a get to /admin/blogposts/1/foo to the foo controller and the show action with namespace admin" do
    Merb::Router.prepare do |r|
      r.namespace(:admin, :path=>"") do |admin|
        admin.resources :blogposts do |blogposts|
          blogposts.resource :foo
        end
      end
    end
    route_to('/blogposts/1/foo', :method => :get).should have_route(:controller => 'foo', :action => 'show', :blogpost_id => '1', :id => nil, :namespace => "admin")
  end

end
