require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

describe "Merb.env helpers" do
  before(:all) do
    @orig_env = Merb.environment
  end
  after(:all) do
    Merb.environment = @orig_env
  end
  
  it "should pickup the environment from env" do
    %w(development test production staging demo).each do |e|
      Merb.environment = e
      Merb.env.should == e
    end
  end
  
  it "should correctly answer the question about which env it's in with symbol or string" do
    %w(development test production staging demo custom).each do |e|
      Merb.environment = e
      Merb.env?(e).should be true
      Merb.env?(e.to_sym).should be_true
    end
  end
  
  it "should answer false if asked for an environment that is not current" do
    %w(development test production staging demo custom).each do |e|
      Merb.environment = e
      Merb.env?(:not_it).should be_false
    end
  end
  
  it "should allow an environment to merge another environments settings" do
    %w(development test production staging demo custom).each do |e|

      Merb.environment = e
      Merb.start_environment
      Merb.merge_env "some_other_env"
      Merb.environment_info.nil?.should be_false
      Merb.environment_info[:merged_envs].first.should == "some_other_env"
    end
  end
  
  
end