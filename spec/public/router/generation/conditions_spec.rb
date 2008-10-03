require File.join(File.dirname(__FILE__), '..', "spec_helper")

describe "When generating URLs," do
  
  describe "a route with one condition" do
    
    it "should generate when the string condition is met" do
      Merb::Router.prepare do
        match("/:account", :account => "walruses").name(:condition)
      end

      url(:condition, :account => "walruses").should == "/walruses"
    end
    
    it "should generate when the regexp condition that is met" do
      Merb::Router.prepare do
        match("/:account", :account => /[a-z]+/).name(:condition)
      end

      url(:condition, :account => "walruses").should == "/walruses"
    end

    it "should not generate if the String condition is not met" do
      Merb::Router.prepare do
        match("/:account", :account => "walruses").name(:condition)
      end

      lambda { url(:condition, :account => "pecans") }.should raise_error(Merb::Router::GenerationError)
    end

    it "should not generate if the Regexp condition is not met" do
      Merb::Router.prepare do
        match("/:account", :account => /[a-z]+/).name(:condition)
      end

      lambda { url(:condition, :account => "29") }.should raise_error(Merb::Router::GenerationError)
    end

    it "should respect Regexp anchors" do
      Merb::Router.prepare do
        match("/:account") do
          match(:account => /^[a-z]+$/).name(:both )
          match(:account => /^[a-z]+/ ).name(:start)
          match(:account => /[a-z]+$/ ).name(:end  )
          match(:account => /[a-z]+/  ).name(:none )
        end
      end

      # Success
      url(:both,  :account => "abc").should == "/abc"
      url(:start, :account => "abc").should == "/abc"
      url(:start, :account => "ab1").should == "/ab1"
      url(:end,   :account => "abc").should == "/abc"
      url(:end,   :account => "1ab").should == "/1ab"
      url(:none,  :account => "abc").should == "/abc"
      url(:none,  :account => "1ab").should == "/1ab"
      url(:none,  :account => "ab1").should == "/ab1"

      # Failure
      lambda { url(:both,  :account => "1ab") }.should raise_error(Merb::Router::GenerationError)
      lambda { url(:both,  :account => "ab1") }.should raise_error(Merb::Router::GenerationError)
      lambda { url(:both,  :account => "123") }.should raise_error(Merb::Router::GenerationError)
      lambda { url(:start, :account => "1ab") }.should raise_error(Merb::Router::GenerationError)
      lambda { url(:start, :account => "123") }.should raise_error(Merb::Router::GenerationError)
      lambda { url(:end,   :account => "ab1") }.should raise_error(Merb::Router::GenerationError)
      lambda { url(:end,   :account => "123") }.should raise_error(Merb::Router::GenerationError)
      lambda { url(:none,  :account => "123") }.should raise_error(Merb::Router::GenerationError)
    end
    
    it "should work with Regexp conditions that contain capturing parentheses" do
      Merb::Router.prepare do
        match("/:domain", :domain => /[a-z]+\.(com|net)/).name(:condition)
      end

      url(:condition, :domain => "foobar.com").should == "/foobar.com"
      lambda { url(:condition, :domain => "foobar.org") }.should raise_error(Merb::Router::GenerationError)
    end

    it "should work with Regexp conditions that contain non-capturing parentheses" do
      Merb::Router.prepare do
        match("/:domain", :domain => /[a-z]+\.(com|net)/).name(:condition)
      end

      url(:condition, :domain => "foobar.com").should == "/foobar.com"
      lambda { url(:condition, :domain => "foobar.org") }.should raise_error(Merb::Router::GenerationError)
    end
    
    it "should not take into consideration conditions on request methods" do
      Merb::Router.prepare do
        match("/one/two", :method => :post).name(:simple)
      end
      
      url(:simple).should == "/one/two"
    end
  end
  
  describe "a route with multiple conditions" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/:one/:two", :one => "hello", :two => %r[^(world|moon)$]).name(:condition)
      end
    end

    it "should generate if all the conditions are met" do
      url(:condition, :one => "hello", :two => "moon").should == "/hello/moon"
    end

    it "should not generate if any of the conditions fail" do
      lambda { url(:condition, :one => "hello") }.should raise_error(Merb::Router::GenerationError)
      lambda { url(:condition, :two => "world") }.should raise_error(Merb::Router::GenerationError)
    end

    it "should append any extra elements to the query string" do
      url(:condition, :one => "hello", :two => "world", :three => "moon").should == "/hello/world?three=moon"
    end
    
  end
  
  describe "a route with nested condition blocks" do
    it "should use both condition blocks to generate" do
      Merb::Router.prepare do
        match("/prefix") do
          to(:controller => "prefix", :action => "show").name(:prefix)
          match("/second").to(:controller => "second").name(:second)
        end
      end
      
      url(:prefix).should == "/prefix"
      url(:second).should == "/prefix/second"
    end
  end
  
end