require File.dirname(__FILE__) + '/spec_helper'

MERB_BIN = File.dirname(__FILE__) + "/../../../bin/merb"

describe Merb::Config do
  before do
    ARGV.replace([])
    Merb::Server.should_receive(:start).and_return(nil)
  end
  
  it "should load the runner adapter by default" do
    Merb.start 
    Merb::Config[:adapter].should == "runner"
  end
  
  it "should load mongrel adapter when running `merb`" do
    load(MERB_BIN)
    Merb::Config[:adapter].should == "mongrel"
  end

  it "should override adapter when running `merb -a other`" do
    ARGV.push *%w[-a other]
    load(MERB_BIN)
    Merb::Config[:adapter].should == "other"
  end  
  
  it "should load irb adapter when running `merb -i`" do
    ARGV << '-i'
    load(MERB_BIN)
    Merb::Config[:adapter].should == "irb"
  end
end