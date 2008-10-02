require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "When recognizing requests," do

  describe "a namespaced route" do
    
    it "should add to the path and prepend the controller with the namespace" do
      Merb::Router.prepare do
        namespace :admin do
          match("/foo").to(:controller => "foos")
        end
      end
      
      lambda { route_for("/foo") }.should raise_not_found
      route_for("/admin/foo").should have_route(:controller => "admin/foos")
    end
    
    it "should yield the new behavior object to the block" do
      Merb::Router.prepare do
        namespace :admin do |a|
          a.match("/foo").to(:controller => "foos")
        end
      end
      
      route_for("/admin/foo").should have_route(:controller => "admin/foos")
    end
    
    it "should be able to prepend the namespace even if the :controller param has been specified already" do
      Merb::Router.prepare do
        to(:controller => "bars") do
          namespace(:admin) do
            match("/foo").register
          end
        end
      end
      
      route_for("/admin/foo").should have_route(:controller => "admin/bars")
    end
    
    it "should be able to prepend the namespace even if :controller has been used in the path already" do
      Merb::Router.prepare do
        match("/:controller") do
          namespace(:marketing).register
        end
      end
      
      route_for("/something/marketing").should have_route(:controller => "marketing/something")
    end
    
    it "should be able to specify the path prefix" do
      Merb::Router.prepare do
        namespace :admin, :path => "administration" do
          match("/foo").to(:controller => "foos")
        end
      end
      
      lambda { route_for("/admin/foo") }.should raise_not_found
      route_for("/administration/foo").should have_route(:controller => "admin/foos")
    end
    
    it "should be able to escape the controller namespace" do
      Merb::Router.prepare do
        namespace :admin do
          match("/login").to(:controller => "/sessions")
        end
      end
      
      route_for("/admin/login").should have_route(:controller => "sessions")
    end
    
    it "should be able to set a namespace without a path prefix" do
      Merb::Router.prepare do
        namespace :admin, :path => "" do
          match("/foo").to(:controller => "foos")
        end
      end
      
      lambda { route_for("/admin/foo") }.should raise_not_found
      route_for("/foo").should       have_route(:controller => "admin/foos")
    end
    
    it "should be able to use nil to set a namespace without a path prefix" do
      Merb::Router.prepare do
        namespace :admin, :path => nil do
          match("/foo").to(:controller => "foos")
        end
      end
      
      lambda { route_for("/admin/foo") }.should raise_not_found
      route_for("/foo").should       have_route(:controller => "admin/foos")
    end
    
    it "should preserve previous conditions" do
      Merb::Router.prepare do
        match :domain => "foo.com" do
          namespace :admin do
            match("/foo").to(:controller => "foos")
          end
        end
      end
      
      lambda { route_for("/admin/foo") }.should raise_not_found
      route_for("/admin/foo", :domain => "foo.com").should have_route(:controller => "admin/foos")
    end
    
    it "should preserve previous params" do
      Merb::Router.prepare do
        to(:awesome => "true") do
          namespace :administration do
            match("/something").to(:controller => "home")
          end
        end
      end
      
      route_for("/administration/something").should have_route(:controller => "administration/home", :awesome => "true")
    end
    
    it "should preserve previous defaults" do
      Merb::Router.prepare do
        defaults(:action => "awesome", :foo => "bar") do
          namespace :baz do
            match("/users").to(:controller => "users")
          end
        end
      end
      
      route_for("/baz/users").should have_route(:controller => "baz/users", :action => "awesome", :foo => "bar")
    end
    
    it "should be preserved through match blocks" do
      Merb::Router.prepare do
        namespace(:admin) do
          match(:host => "admin.domain.com").to(:controller => "welcome")
        end
      end
      
      route_for("/admin", :host => "admin.domain.com").should have_route(:controller => "admin/welcome")
    end
    
    it "should be preserved through to blocks" do
      Merb::Router.prepare do
        namespace(:blah) do
          to(:action => "overload") do
            match("/blah").to(:controller => "weeeee")
          end
        end
      end
      
      route_for("/blah/blah").should have_route(:controller => "blah/weeeee", :action => "overload")
    end
    
    it "should be preserved through defaults blocks" do
      Merb::Router.prepare do
        namespace(:blah) do
          defaults(:action => "overload") do
            match("/blah").to(:controller => "weeeee")
          end
        end
      end
      
      route_for("/blah/blah").should have_route(:controller => "blah/weeeee", :action => "overload")
    end
  end
  
  describe "a nested namespaced route" do
    it "should append the paths and controller namespaces together" do
      Merb::Router.prepare do
        namespace(:foo) do
          namespace(:bar) do
            match("/blah").to(:controller => "weeeee")
          end
        end
      end
      
      route_for('/foo/bar/blah').should have_route(:controller => 'foo/bar/weeeee', :action => 'index')
    end
    
    it "should respec the custom path prefixes set on each namespace" do
      Merb::Router.prepare do
        namespace(:foo, :path => "superfoo") do
          namespace(:bar, :path => "superbar") do
            match("/blah").to(:controller => "weeeee")
          end
        end
      end
      
      route_for('/superfoo/superbar/blah').should have_route(:controller => 'foo/bar/weeeee', :action => 'index')
    end
    
    it "should preserve previous conditions" do
      Merb::Router.prepare do
        namespace(:foo) do
          match(:protocol => 'https') do
            namespace(:bar) do
              match("/blah").to(:controller => "weeeee")
            end
          end
        end
      end
      
      route_for('/foo/bar/blah', :protocol => 'https').should have_route(:controller => 'foo/bar/weeeee', :action => 'index')
    end
    
    it "should preserve previous params" do
      Merb::Router.prepare do
        namespace(:foo) do
          match('/:first') do
            namespace(:bar) do
              match("/blah").to(:controller => "weeeee")
            end
          end
        end
      end
      
      route_for('/foo/one/bar/blah').should have_route(:controller => 'foo/bar/weeeee', :first => 'one', :action => 'index')
    end
    
    it "should preserve previous defaults" do
      Merb::Router.prepare do
        namespace(:foo) do
          defaults(:action => "megaweee") do
            namespace(:bar) do
              match("/blah").to(:controller => "weeeee")
            end
          end
        end
      end
      
      route_for('/foo/bar/blah').should have_route(:controller => 'foo/bar/weeeee', :action => 'megaweee')
    end
      
    it "should be preserved through match blocks" do
      Merb::Router.prepare do
        namespace(:foo) do
          match('/bar') do
            namespace(:baz) do
              match("/blah").to(:controller => "weeeee")
            end
          end
        end
      end
      
      route_for('/foo/bar/baz/blah').should have_route(:controller => 'foo/baz/weeeee')
    end
    
    it "should be preserved through to blocks" do
      Merb::Router.prepare do
        namespace(:foo) do
          match('/bar').to(:controller => 'bar') do
            namespace(:baz) do
              match("/blah").to(:action => "weeeee")
            end
          end
        end
      end
      
      route_for('/foo/bar/baz/blah').should have_route(:controller => 'foo/baz/bar', :action => "weeeee")
    end
    
    it "should be preserved through defaults blocks" do
      Merb::Router.prepare do
        namespace(:foo) do
          defaults(:action => "default_action") do
            namespace(:baz) do
              match("/blah").to(:controller => "blah")
            end
          end
        end
      end
      
      route_for('/foo/baz/blah').should have_route(:controller => 'foo/baz/blah', :action => "default_action")
    end
    
    it "should use the controller prefix from the last time the prefix started with /" do
      Merb::Router.prepare do
        namespace(:foo) do
          namespace(:bar, :controller_prefix => "/bar") do
            match("/home").to(:controller => "home")
          end
        end
      end
      
      route_for("/foo/bar/home").should have_route(:controller => "bar/home")
    end
  end

  # I'm not sure if a) these are in the right spec file and b) if they are needed at all
  describe "a namespaced resource" do
    
    it "should match a get to /admin/foo/blogposts to the blogposts controller and index action" do
      Merb::Router.prepare do
        namespace :admin do
          resource :foo do
            resources :blogposts
          end
        end
      end
      
      route_for('/admin/foo/blogposts', :method => :get).should have_route(:controller => 'admin/blogposts', :action => 'index', :id => nil)
    end

    it "should match a get to /admin/blogposts/1/foo to the foo controller and the show action" do
      Merb::Router.prepare do
        namespace :admin do
          resources :blogposts do
            resource :foo
          end
        end
      end
      
      route_for('/admin/blogposts/1/foo', :method => :get).should have_route(:controller => 'admin/foos', :action => 'show', :blogpost_id => '1', :id => nil)
    end
  
    it "should match a get to /my_admin/blogposts to the blogposts controller with a custom patch setting" do
      Merb::Router.prepare do
        namespace(:admin, :path => "my_admin") do
          resources :blogposts
        end
      end
      
      route_for('/my_admin/blogposts', :method => :get).should have_route(:controller => 'admin/blogposts', :action => 'index', :id => nil)
    end

    it "should match a get to /admin/blogposts/1/foo to the foo controller and the show action with namespace admin" do
      Merb::Router.prepare do
        namespace(:admin, :path => "") do
          resources :blogposts do
            resource :foo
          end
        end
      end
      
      route_for('/blogposts/1/foo', :method => :get).should have_route(:controller => 'admin/foos', :action => 'show', :blogpost_id => '1', :id => nil)
    end
  end

  # This doesn't work anymore
  # ---
  # describe "a nested namespaced resource" do
  #   it "should match a get to /admin/superadmin/blogposts to the blogposts controller and index action and a nested namespace" do
  #     pending "Awww crap, this is the single spec that instance_eval fails on"
  #     Merb::Router.prepare do
  #       namespace :admin do |admin|
  #         r.namespace :superadmin do |superadmin|
  #           admin.resources :blogposts
  #         end
  #       end
  #     end
  #     
  #     route_for('/admin/blogposts', :method => :get).should have_route(:controller => 'admin/blogposts', :action => 'index', :id => nil)
  #   end
  # end
end