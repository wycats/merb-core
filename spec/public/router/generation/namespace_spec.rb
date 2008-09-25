require File.join(File.dirname(__FILE__), '..', "spec_helper")

describe "When generating URLs," do
  
  describe "a namespaced named route" do
    
    it "should add the prefix to the route name and url" do
      Merb::Router.prepare do
        namespace(:admin) do
          match("/login").to(:controller => "home").name(:login)
        end
      end

      url(:admin_login).should == "/admin/login"
    end
    
    it "should be able to specify the path prefix as an option" do
      Merb::Router.prepare do
        namespace(:admin, :path => "supauser") do
          match("/login").to(:controller => "home").name(:login)
        end
      end
      
      url(:admin_login).should == "/supauser/login"
    end
    
    it "should be able to specify the name prefix as an option" do
      Merb::Router.prepare do
        namespace(:admin, :name_prefix => "supa") do
          match("/login").to(:controller => "home").name(:login)
        end
      end
      
      url(:supa_login).should == "/admin/login"
    end
    
    it "should be able to not add a path prefix" do
      Merb::Router.prepare do
        namespace(:admin, :path => "") do
          match("/login").to(:controller => "home").name(:login)
        end
      end
      
      url(:admin_login).should == "/login"
    end
    
    it "should not use the name prefix if the route is named with #full_name" do
      Merb::Router.prepare do
        namespace(:admin) do
          match("/:controller").full_name(:controller)
          match("/login").to(:controller => "home").full_name(:login)
        end
      end
      
      url(:controller, :controller => 'foobar').should == "/admin/foobar"
      url(:login).should                               == "/admin/login"
    end
    
    it "should be able to prepend to the name_prefix" do
      Merb::Router.prepare do
        namespace(:admin) do
          match("/login").to(:controller => "home").name(:do, :login)
        end
      end
      
      url(:do_admin_login).should == "/admin/login"
    end
  end
  
  describe "a nested namespaced named route" do
    it "should combine the namespaces" do
      Merb::Router.prepare do
        namespace(:foo) do
          namespace(:bar) do
            match("/login").to(:controller => "home").name(:login)
          end
        end
      end
      
      url(:foo_bar_login).should == "/foo/bar/login"
    end
    
    it "should only use the first namespace" do
      Merb::Router.prepare do
        namespace(:foo) do |f|
          namespace(:bar) do
            f.match("/login").to(:controller => "home").name(:login)
          end
        end
      end
      
      url(:foo_login).should == "/foo/login"
    end
    
    # This is broken :(
    # ---
    # it "should only use the second namespace" do
    #   pending "This doesn't work for now"
    #   Merb::Router.prepare do |r|
    #     r.namespace(:foo) do |f|
    #       r.namespace(:bar) do |b|
    #         b.match("/login").to(:controller => "home").name(:login)
    #       end
    #     end
    #   end
    #   
    #   url(:bar_login).should == "/bar/login"
    # end
  end
end