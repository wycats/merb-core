require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))

given "we set an ivar" do
  @foo = 7
end

describe "a spec that reuses a given block", :given => "we set an ivar" do
  it "sees the results of the given block" do
    @foo.should == 7
  end
end