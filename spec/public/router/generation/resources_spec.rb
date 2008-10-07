require File.join(File.dirname(__FILE__), '..', "spec_helper")

class User
  def id    ; 5  ; end
  def ohhai ; 10 ; end
end

describe "When generating URLs," do
  
  describe "a resource collection route" do
    
    before(:each) do
      Merb::Router.prepare do
        identify :id do
          resources :users
          identify :ohhai do
            resources :admins
          end
        end
      end
    end
    
    it "should provide an index route" do
      url(:users).should == "/users"
    end
    
    it "should provide a new route" do
      url(:new_user).should == "/users/new"
    end
    
    it "should provide a show route" do
      url(:user, :id => 1).should   == "/users/1"
    end
    
    it "should be able to provide a string to generate a show route" do
      url(:user, :id => "1").should == "/users/1"
    end
    
    it "should be able to provide an object that responds to the default identifier method" do
      url(:user, :id => User.new).should == "/users/5"
    end
    
    it "should be able to provide an object that responds to a custom identifier method" do
      url(:admin, :id => User.new).should == "/admins/10"
    end
    
    it "should provide an edit route" do
      url(:edit_user, :id => 1).should   == "/users/1/edit"
    end
    
    it "should be able to provide a string to generate a show route" do
      url(:edit_user, :id => "1").should == "/users/1/edit"
    end
    
    it "should be able to provide an object that responds to the default identifier method" do
      url(:edit_user, :id => User.new).should == "/users/5/edit"
    end
    
    it "should be able to provide an object that responds to a custom identifier method" do
      url(:edit_admin, :id => User.new).should == "/admins/10/edit"
    end
    
    it "should provide a delete route" do
      url(:delete_user, :id => 1).should   == "/users/1/delete"
    end
    
    it "should be able to provide a string to generate a delete route" do
      url(:delete_user, :id => "1").should == "/users/1/delete"
    end
    
    it "should be able to provide an object that responds to the default identifier method" do
      url(:delete_user, :id => User.new).should == "/users/5/delete"
    end
    
    it "should be able to provide an object that responds to a custom identifier method" do
      url(:delete_admin, :id => User.new).should == "/admins/10/delete"
    end
    
    it "should be able to specify a class that does not exist" do
      lambda do
        Merb::Router.prepare do
          resources :emails, "EmailBlahBlah"
        end
      end.should_not raise_error
    end
    
    it "should be able to specify different keys than :id" do
      Merb::Router.prepare do
        resources :users, :keys => [:account, :name]
      end
      
      url(:users).should                                               == "/users"
      url(:new_user).should                                            == "/users/new"
      url(:user, :account => "github", :name => "foo").should          == "/users/github/foo"
      url(:edit_user, :account => "lighthouse", :name => "bar").should == "/users/lighthouse/bar/edit"
      url(:delete_user, :account => "hello", :name => "world").should  == "/users/hello/world/delete"
      # -- Bad --
      lambda { url(:user, :id => 1) }.should raise_error(Merb::Router::GenerationError)
    end
    
    [:key, :keys].each do |option|
      it "should work with a single #{option.inspect} entry" do
        Merb::Router.prepare do
          resources :users, option => :name
        end

        url(:users).should                          == "/users"
        url(:new_user).should                       == "/users/new"
        url(:user,        :name => "foo").should    == "/users/foo"
        url(:edit_user,   :name => "bar").should    == "/users/bar/edit"
        url(:delete_user, :name => "world").should  == "/users/world/delete"
        # -- Bad --
        lambda { url(:user, :id => 1) }.should raise_error(Merb::Router::GenerationError)
      end
    end
    
    it "should be able to specify the path of the resource" do
      Merb::Router.prepare do
        resources :users, :path => "admins"
      end
      
      url(:users).should == "/admins"
    end
    
    it "should be able to prepend the name" do
      Merb::Router.prepare do
        resources :users, :name_prefix => :admin
      end
      
      url(:admin_users).should                 == "/users"
      url(:new_admin_user).should              == "/users/new"
      url(:admin_user, :id => 1).should        == "/users/1"
      url(:edit_admin_user, :id => 1).should   == "/users/1/edit"
      url(:delete_admin_user, :id => 1).should == "/users/1/delete"
    end
    
    it "should be able to add extra collection routes through the options" do
      Merb::Router.prepare do
        resources :users, :collection => {:hello => :get, :goodbye => :post}
      end
      
      url(:hello_users).should   == "/users/hello"
      url(:goodbye_users).should == "/users/goodbye"
    end
    
    it "should be able to add extra collection routes in the block" do
      Merb::Router.prepare do
        resources :users do
          collection :hello
          collection :goodbye
        end
      end
      
      url(:hello_users).should   == "/users/hello"
      url(:goodbye_users).should == "/users/goodbye"
    end
    
    it "should be able to add extra member routes" do
      Merb::Router.prepare do
        resources :users, :member => {:hello => :get, :goodbye => :post}
      end
      
      url(:hello_user, :id => 1).should   == "/users/1/hello"
      url(:goodbye_user, :id => 1).should == "/users/1/goodbye"
    end
    
    it "should be able to add extra member routes" do
      Merb::Router.prepare do
        resources :users do
          member :hello
          member :goodbye
        end
      end
      
      url(:hello_user, :id => 1).should   == "/users/1/hello"
      url(:goodbye_user, :id => 1).should == "/users/1/goodbye"
    end
    
    it "should be able to specify arbitrary sub routes" do
      Merb::Router.prepare do
        resources :users do
          match("/:foo", :foo => %r[^foo-\d+$]).to(:action => "foo").name(:foo)
        end
      end
      
      url(:user_foo, :user_id => 2, :foo => "foo-123").should == "/users/2/foo-123"
    end
    
    it "should allow the singular name to be set" do
      Merb::Router.prepare do
        resources :blogposts, :singular => :blogpoost
      end
      
      url(:blogposts).should == "/blogposts"
      url(:blogpoost, 1).should == "/blogposts/1"
    end
    
  end
  
  describe "a resource object route" do
    
    before(:each) do
      Merb::Router.prepare do
        resource :form
      end
    end
    
    it "should provide a show route" do
      url(:form).should == "/form"
    end
    
    it "should provide a new route" do
      url(:new_form).should == "/form/new"
    end
    
    it "should provide an edit route" do
      url(:edit_form).should == "/form/edit"
    end
    
    it "should provide a delete route" do
      url(:delete_form).should == "/form/delete"
    end
    
    it "should not provide an index route" do
      lambda { url(:forms) }.should raise_error(Merb::Router::GenerationError)
    end
    
    it "should be able to specify extra actions through the options" do
      Merb::Router.prepare do
        resource :form, :member => { :hello => :get, :goodbye => :post }
      end
      
      url(:hello_form).should   == "/form/hello"
      url(:goodbye_form).should == "/form/goodbye"
    end
    
    it "should be able to specify extra actions through the block" do
      Merb::Router.prepare do
        resource :form do
          member :hello
          member :goodbye
        end
      end
      
      url(:hello_form).should   == "/form/hello"
      url(:goodbye_form).should == "/form/goodbye"
    end
    
    it "should be able to specify arbitrary sub routes" do
      Merb::Router.prepare do
        resource :form do
          match("/:foo", :foo => %r[^foo-\d+$]).to(:action => "foo").name(:foo)
        end
      end
      
      url(:form_foo, :foo => "foo-123").should == "/form/foo-123"
    end
    
  end
  
  describe "a nested resource route" do
    
    before(:each) do
      Merb::Router.prepare do
        resources :users do
          collection :gaga
          resources :comments do
            collection :hello
            member     :goodbye
          end
        end
      end
    end
    
    it "should provide an index route" do
      url(:user_comments, :user_id => 5).should == "/users/5/comments"
    end
    
    it "should provide a new route" do
      url(:new_user_comment, :user_id => 5).should == "/users/5/comments/new"
    end
    
    it "should provide a show route" do
      url(:user_comment, :user_id => 5, :id => 1).should == "/users/5/comments/1"
    end
    
    it "should provide an edit route" do
      url(:edit_user_comment, :user_id => 5, :id => 1).should == "/users/5/comments/1/edit"
    end
    
    it "should provide a delete route" do
      url(:delete_user_comment, :user_id => 5, :id => 1).should == "/users/5/comments/1/delete"
    end
    
    it "should not have a gaga route" do
      lambda { url(:gaga_user_comments, :user_id => 5) }
    end
    
    it "should provide a hello collection route" do
      url(:hello_user_comments, :user_id => 5).should == "/users/5/comments/hello"
    end
    
    it "should provide a goodbye member route" do
      url(:goodbye_user_comment, :user_id => 5, :id => 1).should == "/users/5/comments/1/goodbye"
    end
    
  end
  
  describe "a resource route nested in a conditional block" do
    it "should use previously set conditions" do
      Merb::Router.prepare do
        match("/prefix") do
          resources :users
        end
      end
      
      url(:users).should == "/prefix/users"
    end
  end
end