require File.join(File.dirname(__FILE__), "spec_helper")

describe "env_for" do
  describe "with :method" do
    before(:each) do
      @orig_env = { :method => "POST" }
    end
  
    it "should preserve the passed environment" do
      env_for("/", @orig_env)
      @orig_env.should == { :method => "POST" }
    end

    it "should return REQUEST_PATH and REQUEST_METHOD" do
      env_for("/", @orig_env).should == { "REQUEST_PATH" => "/", "REQUEST_METHOD" => "POST" }
    end
  end

  describe "with :user_agent" do
    before(:each) do
      @orig_env = { :user_agent => "Safari" }
    end
  
    it "should preserve the passed environment" do
      env_for("/", @orig_env)
      @orig_env.should == { :user_agent => "Safari" }
    end

    it "should return REQUEST_PATH and HTTP_USER_AGENT" do
      env_for("/", @orig_env).should == { "REQUEST_PATH" => "/", "HTTP_USER_AGENT" => "Safari" }
    end
  end
end
