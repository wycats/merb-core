require File.join(File.dirname(__FILE__), "spec_helper")
require File.join(File.dirname(__FILE__), "controllers", "url")
require 'ostruct'

class Orm     < OpenStruct ; def id ; @table[:id] ; end ; end
class User    < Orm ; end
class Comment < Orm ; end

module Namespaced
  class User < Orm ; end
end

describe Merb::Controller, " #resource" do
  
  before(:each) do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::Url, :index)
  end
  
  describe "generating a resource collection route" do
    
    before(:each) do
      Merb::Router.prepare do
        identify :id do
          resources :users
        end
      end
      
      @user = User.new(:id => 5)
    end
    
    it "should generate the url for the collection" do
      @controller.resource(:users).should == "/users"
    end
    
    it "should generate the url for a member of the collection" do
      @controller.resource(@user).should == "/users/5"
    end
    
    it "should generate the url for a new member" do
      @controller.resource(:users, :new).should == "/users/new"
    end
    
    it "should generate the url for editing a member of the collection" do
      @controller.resource(@user, :edit).should == "/users/5/edit"
    end
    
    it "should generate the url for deleting a member of the collection" do
      @controller.resource(@user, :delete).should == "/users/5/delete"
    end
    
    it "should be able to specify extra actions through the options" do
      Merb::Router.prepare do
        identify :id do
          resources :users, :collection => { :hello => :get }, :member => { :goodbye => :post }
        end
      end
      
      @controller.resource(:users, :hello).should  == "/users/hello"
      @controller.resource(@user, :goodbye).should == "/users/5/goodbye"
    end
    
    it "should be able to specify extra actions through the block" do
      Merb::Router.prepare do
        identify :id do
          resources :users do
            collection :hello
            member     :goodbye
          end
        end
      end
      
      @controller.resource(:users, :hello).should  == "/users/hello"
      @controller.resource(@user, :goodbye).should == "/users/5/goodbye"
    end
    
  end
  
  describe "generating a resource member route" do
    
    before(:each) do
      Merb::Router.prepare do
        resource :user
      end
      
      @user = User.new(:id => 5)
    end
    
    it "should generate the url for the member" do
      @controller.resource(:user).should == "/user"
    end
    
    it "should generate the url for a new member" do
      @controller.resource(:user, :new).should == "/user/new"
    end
    
    it "should generate the url for editing the member" do
      @controller.resource(:user, :edit).should == "/user/edit"
    end
    
    it "should generate the url for deleting the member" do
      @controller.resource(:user, :delete).should == "/user/delete"
    end
    
    it "should be able to specify extra actions through the options" do
      Merb::Router.prepare do
        resource :user, :member => { :hello => :get }
      end
      
      @controller.resource(:user, :hello).should == "/user/hello"
    end
    
    it "should be able to specify extra options through the block" do
      Merb::Router.prepare do
        resource :user do
          member :hello
        end
      end
      
      @controller.resource(:user, :hello).should == "/user/hello"
    end
    
  end
  
  describe "a nested resource collection route" do
    
    before(:each) do
      Merb::Router.prepare do
        identify :id do
          resources :users do
            resources :comments
          end
        end
      end
      
      @user    = User.new(:id => 5)
      @comment = Comment.new(:id => 8)
    end
    
    it "should generate the url for the collection" do
      @controller.resource(@user, :comments).should == "/users/5/comments"
    end
    
    it "should generate the url for a member of the collection" do
      @controller.resource(@user, @comment).should == "/users/5/comments/8"
    end
    
    it "should generate the url for a new member" do
      @controller.resource(@user, :comments, :new).should == "/users/5/comments/new"
    end
    
    it "should generate the url for editing a member of the collection" do
      @controller.resource(@user, @comment, :edit).should == "/users/5/comments/8/edit"
    end
    
    it "should generate the url for deleting a member of the collection" do
      @controller.resource(@user, @comment, :delete).should == "/users/5/comments/8/delete"
    end
  end
  
  describe "nested member routes" do
    
    before(:each) do
      Merb::Router.prepare do
        resource :user do
          resource :comment
        end
      end
    end
    
    it "should generate the url for the nested member" do
      @controller.resource(:user, :comment).should == "/user/comment"
    end
    
    it "should generate the url for a new nested member" do
      @controller.resource(:user, :comment, :new).should == "/user/comment/new"
    end
    
    it "should generate the url for editing the nested member" do
      @controller.resource(:user, :comment, :edit).should == "/user/comment/edit"
    end
    
    it "should generate the url for deleting the nested member" do
      @controller.resource(:user, :comment, :delete).should == "/user/comment/delete"
    end
  end
  
  describe "a namespaced resource collection route" do
    
    before(:each) do
      Merb::Router.prepare do
        identify(:id).namespace(:admin) do
          resources :users
        end
      end
      
      @user = User.new(:id => 5)
    end
    
    it "should generate the url for the collection" do
      @controller.resource(:admin, :users).should == "/admin/users"
    end
    
    it "should generate the url for a member of the collection" do
      @controller.resource(@user).should == "/users/5"
    end
    
    it "should generate the url for a new member" do
      @controller.resource(:users, :new).should == "/users/new"
    end
    
    it "should generate the url for editing a member of the collection" do
      @controller.resource(@user, :edit).should == "/users/5/edit"
    end
    
    it "should generate the url for deleting a member of the collection" do
      @controller.resource(@user, :delete).should == "/users/5/delete"
    end
    
  end
  
  describe "a resource collection route with a named segment prefix" do
    
    before(:each) do
      Merb::Router.prepare do
        identify(:id).match("/:account") do
          resources :users
        end
      end
      
      @user = User.new(:id => 5)
    end
    
    it "should generate the url for the collection" do
      @controller.resource(:users, :account => "foo").should == "/foo/users"
    end
    
    it "should generate the url for a member of the collection" do
      @controller.resource(@user, :account => "foo").should == "/foo/users/5"
    end
    
    it "should generate the url for a new member" do
      @controller.resource(:users, :new, :account => "foo").should == "/foo/users/new"
    end
    
    it "should generate the url for editing a member of the collection" do
      @controller.resource(@user, :edit, :account => "foo").should == "/foo/users/5/edit"
    end
    
    it "should generate the url for deleting a member of the collection" do
      @controller.resource(@user, :delete, :account => "foo").should == "/foo/users/5/delete"
    end
    
  end
  
  describe "a resource collection with a specified class" do
    
    before(:each) do
      Merb::Router.prepare do
        identify :id do
          resources :admins, User do
            resources :notes, "Comment"
          end
        end
      end
      
      @admin = User.new(:id => 5)
      @note  = Comment.new(:id => 8)
    end
    
    it "should generate the url for the collection" do
      @controller.resource(:admins).should == "/admins"
    end
    
    it "should generate the url for a member of the collection" do
      @controller.resource(@admin).should == "/admins/5"
    end
    
    it "should generate the url for a new member" do
      @controller.resource(:admins, :new).should == "/admins/new"
    end
    
    it "should generate the url for editing a member of the collection" do
      @controller.resource(@admin, :edit).should == "/admins/5/edit"
    end
    
    it "should generate the url for deleting a member of the collection" do
      @controller.resource(@admin, :delete).should == "/admins/5/delete"
    end
    
    it "should generate the url for the nested collection" do
      @controller.resource(@admin, :notes).should == "/admins/5/notes"
    end
    
    it "should generate the url for a member of the nested collection" do
      @controller.resource(@admin, @note).should == "/admins/5/notes/8"
    end
    
    it "should generate the url for a new nested member" do
      @controller.resource(@admin, :notes, :new).should == "/admins/5/notes/new"
    end
    
    it "should generate the url for editing a member of the nested collection" do
      @controller.resource(@admin, @note, :edit).should == "/admins/5/notes/8/edit"
    end
    
    it "should generate the url for deleting a member of the nested collection" do
      @controller.resource(@admin, @note, :delete).should == "/admins/5/notes/8/delete"
    end
    
  end
  
  describe "a resource collection with a specified namespaced class" do
    
    it "should generate the url for the namespaced resource when passed as a constant" do
      Merb::Router.prepare do
        identify :id do
          resources :users, User
          match("/hello").resources :users, Namespaced::User
        end
      end
      
      resource(Namespaced::User.new(:id => 5)).should == "/hello/users/5"
    end
    
    it "should generate the url for the namespaced resource when passed as a string" do
      Merb::Router.prepare do
        identify :id do
          resources :users, User
          match("/hello").resources :users, "Namespaced::User"
        end
      end
      
      resource(Namespaced::User.new(:id => 5)).should == "/hello/users/5"
    end
    
  end
  
  
end