# The before/after filters in BootLoaders are considered public API.
#
# However, Merb::BootLoader.subclasses is not considered public API and should not be used in plugins.

require File.join(File.dirname(__FILE__), "spec_helper")

class Merb::BootLoader::AfterTest < Merb::BootLoader
  after Merb::BootLoader::BeforeAppLoads
  
  def self.run
  end
end

class Merb::BootLoader::BeforeTest < Merb::BootLoader
  before Merb::BootLoader::Templates
  
  def self.run
  end
end

describe "The BootLoader" do
  
  it "should support adding a BootLoader after another" do
    idx = Merb::BootLoader.subclasses.index("Merb::BootLoader::BeforeAppLoads")
    Merb::BootLoader.subclasses.index("Merb::BootLoader::AfterTest").should == idx + 1
  end

  it "should support adding a BootLoader before another" do
    idx = Merb::BootLoader.subclasses.index("Merb::BootLoader::Templates")
    Merb::BootLoader.subclasses.index("Merb::BootLoader::BeforeTest").should == idx - 1
  end
  
end