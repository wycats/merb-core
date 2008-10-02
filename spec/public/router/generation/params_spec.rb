require File.join(File.dirname(__FILE__), '..', "spec_helper")

describe "When generating URLs," do
  
  describe "passing params in anonymously to routes" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/:first/:second/:third").name(:ordered)
      end
    end
    
    it "should match the params to the segment variables in the order that they were declared" do
      url(:ordered, "one", "two", "three").should == "/one/two/three"
    end
    
    it "should not generate unless all the params are present" do
      lambda { url(:ordered, "one", "two") }.should raise_error(Merb::Router::GenerationError)
    end
    
    it "should not generate if there are too many anonymous params" do
      lambda { url(:ordered, "one", "two", "three", "four") }.should raise_error(Merb::Router::GenerationError)
    end
    
    it "should be able to mix and match with the params hash" do
      url(:ordered, "one", "two", :third => "three").should == "/one/two/three"
    end
    
    it "should be able to set query params with the params hash" do
      url(:ordered, "one", "two", "three", :fourth => "four").should == "/one/two/three?fourth=four"
    end
    
    it "should give precedence to the params hash" do
      url(:ordered, "one", "two", :first => "un").should             == "/un/one/two"
      url(:ordered, "one", :first => "un", :second => "deux").should == "/un/deux/one"
      url(:ordered, "one", :first => "un", :third => "trois").should == "/un/one/trois"
      url(:ordered, "one", "two", :second => "deux").should          == "/one/deux/two"
    end
    
    it "should raise an exception when there are two many anonymous params after the named params were placed" do
      lambda { url(:ordered, "one", "two", :first => "un", :second => "deux") }.should raise_error(Merb::Router::GenerationError)
    end
  end
  
  describe "passing params anonymously to resource routes with identifiers" do
    
    module AP
      class ORM ; end
      class User    < ORM ; def id ; 10 ; end ; end
      class Comment < ORM ; def id ; 25 ; end ; end
    end
    
    before(:each) do
      Merb::Router.prepare do
        identify AP::ORM => :id do
          resources :users do
            resources :comments
          end
        end
      end
    end
    
    it "should work the same as normal routes" do
      url(:user,         AP::User.new                 ).should == "/users/10"
      url(:user_comment, AP::User.new, AP::Comment.new).should == "/users/10/comments/25"
      url(:user_comment, 30,           AP::Comment.new).should == "/users/30/comments/25"
      url(:user_comment, AP::User.new, "42"           ).should == "/users/10/comments/42"
    end
    
  end
  
end