require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))

given "we set an ivar" do
  @foo = 7
end

describe "a spec that reuses a given block", :given => "we set an ivar" do
  it "sees the results of the given block" do
    @foo.should == 7
  end
end

describe "a spec that does not reuse a given block" do
  it "does not see the given block" do
    @foo.should == nil
  end
end