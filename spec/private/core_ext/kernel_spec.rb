require File.dirname(__FILE__) + '/../../spec_helper'

describe "Kernel#require" do
  before do
    @logger = StringIO.new
    Merb.logger = Merb::Logger.new(@logger)
  end

  it "should be able to require and throw a useful error message" do
    Kernel.stub!(:require).with("redcloth").and_raise(LoadError)
    Merb.logger.should_receive(:error!).with("foo")
    Kernel.rescue_require("redcloth", "foo")
  end
end



describe "Kernel#caller" do
  it "should be able to determine caller info" do
    __caller_info__.should be_kind_of(Array)
  end

  it "should be able to get caller lines" do
    __caller_lines__(__caller_info__[0], __caller_info__[1], 4).length.should == 9
    __caller_lines__(__caller_info__[0], __caller_info__[1], 4).should be_kind_of(Array)
  end
end



describe "Kernel#extract_options_from_args!" do
  it "should extract options from args" do
    args = ["foo", "bar", {:baz => :bar}]
    Kernel.extract_options_from_args!(args).should == {:baz => :bar}
    args.should == ["foo", "bar"]
  end
end



describe "Kernel#debugger" do
  it "should throw a useful error if there's no debugger" do
    Merb.logger.should_receive(:info!).with "\n***** Debugger requested, but was not " +
      "available: Start server with --debugger " +
      "to enable *****\n"
    Kernel.debugger
  end
end


describe "Kernel#dependency" do
  it "adds dependency to the list" do
    lambda { dependency("dm_merb", ">= 0.9") }.should change(Merb::BootLoader::Dependencies.dependencies, :size)
  end

  it "deferres load to boot loader run" do
    Object.should_not_receive(:full_const_get)
    dependency("dm_merb", ">= 0.9")
  end
end
