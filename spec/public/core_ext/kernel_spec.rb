require File.join(File.dirname(__FILE__), "spec_helper")
$:.push File.join(File.dirname(__FILE__), "fixtures")

describe Kernel, "#dependency" do
  it "works even when the BootLoader has already finished" do
    dependency "core_ext_dependency"
    defined?(CoreExtDependency).should_not be_nil
  end
end