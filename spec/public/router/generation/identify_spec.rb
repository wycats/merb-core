require File.join(File.dirname(__FILE__), '..', "spec_helper")

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

  class User    < ORM
    def to_s ; "user" ; end
    def name ; "carl" ; end
  end

  class Something
    def to_s ; "hello" ; end
  end

  class WithInclusions
    include Resource
  end
end

describe "When generating URLs," do
  
  before(:each) do
    Merb::Router.prepare do
      identify ID::Account => :url, ID::User => :name, ID::ORM => :id, ID::Resource => :identifier do
        match("/:account") do
          resources :users
        end
      end
      
      match("/resources/:id").name(:resource)
    end
  end
  
  describe "a route with custom identifiers" do
    
    it "should use #to_s if no other identifier is set" do
      url(:resource, :id => ID::Article.new).should   == "/resources/article"
      url(:resource, :id => ID::Account.new).should   == "/resources/account"
      url(:resource, :id => ID::User.new).should      == "/resources/user"
      url(:resource, :id => ID::Something.new).should == "/resources/hello"
    end
    
    it "should use the identifier for the object" do
      url(:user, :account => ID::Account.new, :id => ID::User.new).should == "/awesome/users/carl"
    end
    
    it "should be able to use identifiers for parent classes" do
      url(:user, :account => ID::Article.new, :id => 1).should == "/10/users/1"
    end
    
    it "should be able to use identifiers for included modules" do
      url(:user, :account =>ID:: WithInclusions.new, :id => '1').should == "/included/users/1"
    end
    
    it "should not require a block" do
      Merb::Router.prepare do
        identify(ID::Account => :url).match("/:account").name(:account)
      end
      
      url(:account, :account => ID::Account.new).should == "/awesome"
    end
    
    it "should combine identifiers when nesting" do
      Merb::Router.prepare do
        identify ID::Account => :url do
          identify ID::User => :name do
            match("/:account").resources :users
          end
        end
      end
      
      url(:user, :account => ID::Account.new, :id => ID::User.new).should == "/awesome/users/carl"
    end
    
    it "should retain previously set conditions" do
      Merb::Router.prepare do
        match("/:account") do
          register.name(:account)
          identify ID::Account => :url do
            resources :users
          end
        end
      end
      
      url(:account, :account => ID::Account.new).should == "/account"
      url(:user, :account => ID::Account.new, :id => ID::User.new).should == "/awesome/users/user"
    end
    
  end
  
end