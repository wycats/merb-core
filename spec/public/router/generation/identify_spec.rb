require File.join(File.dirname(__FILE__), '..', "spec_helper")

# Namespacing everything so that all the spec classes aren't shared
# across other specs
module ID
  class ORM ; end

  module Resource
    def identifier
      "included"
    end
  end

  class Article < ORM 
    def id   ; 10        ; end
    def to_s ; "article" ; end
  end

  class Account < ORM
    def to_s ; "account"  ; end
    def url  ; "awesome" ; end
  end

  class User < ORM
    def id         ; 10     ; end
    def to_s       ; "user" ; end
    def name       ; "carl" ; end
    def first_name ; "john" ; end
    def last_name  ; "doe"  ; end
  end

  class Something
    def to_s ; "hello" ; end
  end

  class WithInclusions
    include Resource
  end
  
  describe "When generating URLs," do

    before(:each) do
      Merb::Router.prepare do
        identify Account => :url, User => :name, ORM => :id, Resource => :identifier do
          match("/:account") do
            resources :users
          end
        end

        match("/resources/:id").name(:resource)
      end
    end

    describe "a route with custom identifiers" do

      it "should use #to_s if no other identifier is set" do
        url(:resource, :id => Article.new).should   == "/resources/article"
        url(:resource, :id => Account.new).should   == "/resources/account"
        url(:resource, :id => User.new).should      == "/resources/user"
        url(:resource, :id => Something.new).should == "/resources/hello"
      end
      
      it "should use #to_s if no other identifier is set when params are anonymous" do
        url(:resource, Article.new).should   == "/resources/article"
        url(:resource, Account.new).should   == "/resources/account"
        url(:resource, User.new).should      == "/resources/user"
        url(:resource, Something.new).should == "/resources/hello"
      end

      it "should use the identifier for the object" do
        url(:user, :account => Account.new, :id => User.new).should == "/awesome/users/carl"
      end
      
      it "should use the identifier for the object when the params are anonymous" do
        url(:user, Account.new, User.new).should == "/awesome/users/carl"
      end

      it "should be able to use identifiers for parent classes" do
        url(:user, :account => Article.new, :id => 1).should == "/10/users/1"
      end
      
      it "should be able to use identifiers for parent classes when the params are anonymous" do
        url(:user, Article.new, 1).should == "/10/users/1"
      end

      it "should be able to use identifiers for included modules" do
        url(:user, :account => WithInclusions.new, :id => '1').should == "/included/users/1"
      end
      
      it "should be able to use identifiers for included modules when the params are anonymous" do
        url(:user, WithInclusions.new, '1').should == "/included/users/1"
      end
      
      it "should be able to specify an array of identifiers" do
        Merb::Router.prepare do
          identify(User => [:last_name, :first_name]) do
            match("/users/:last_name/:first_name").name(:users)
          end
        end
        
        url(:users, :last_name => User.new, :first_name => User.new).should == "/users/doe/john"
      end
      
      it "should be able to specify an array of identifiers when the params are anonymous" do
        Merb::Router.prepare do
          identify(User => [:last_name, :first_name]) do
            match("/users/:last_name/:first_name").name(:users)
          end
        end
        
        url(:users, User.new).should == "/users/doe/john"
      end
      
      it "should be able to treat :id correctly with Array identifiers" do
        Merb::Router.prepare do
          identify(User => [:name, :id]) do
            resources :users, :keys => [:name, :id] do
              resources :comments
            end
          end
        end
        
        url(:user_comments, :name => User.new, :user_id => User.new).should == "/users/carl/10/comments"
      end

      it "should not require a block" do
        Merb::Router.prepare do
          identify(Account => :url).match("/:account").name(:account)
        end

        url(:account, :account => Account.new).should == "/awesome"
      end

      it "should combine identifiers when nesting" do
        Merb::Router.prepare do
          identify Account => :url do
            identify User => :name do
              match("/:account").resources :users
            end
          end
        end

        url(:user, :account => Account.new, :id => User.new).should == "/awesome/users/carl"
      end

      it "should retain previously set conditions" do
        Merb::Router.prepare do
          match("/:account") do
            register.name(:account)
            identify Account => :url do
              resources :users
            end
          end
        end

        url(:account, :account => Account.new).should == "/account"
        url(:user, :account => Account.new, :id => User.new).should == "/awesome/users/user"
      end

    end

  end
end