require File.dirname(__FILE__) + '/../../spec_helper'

describe "Kernel#dependency" do
  
  before do
    File.stub!(:directory?).with(Merb.root / "gems").and_return(true)
    Gem.stub!(:use_paths)
    Gem.stub!(:clear_paths)
    Merb.logger = Merb::Logger.new(File.open("/dev/null", "w"))
    Merb::BootLoader.before_load_callbacks = []
  end
  
  ["dependency", "dependencies"].each do |meth|
    it "loads in files from the local gem-cache first (with #{meth})" do
      Gem.should_receive(:activate).with("json_pure", true).and_return(true)
      Kernel.send meth, "json_pure"
      Merb::BootLoader::BeforeAppRuns.run
    end
  
    it "does a require if it can't find it in either gem cache (with #{meth})" do
      Gem.stub!(:activate).twice.with("RedCloth", true).and_raise(LoadError)
      Kernel.should_receive(:require).with("RedCloth")
      Kernel.send meth, "RedCloth"
      
      Merb::BootLoader::BeforeAppRuns.run
    end
  end

  it "can call dependencies with an array" do
    Kernel.should_receive(:dependency).twice.and_return(true)
    Kernel.dependencies ["RedCloth", "foo_bar"]
  end
  
  it "can call dependencies with a hash" do
    Kernel.should_receive(:dependency).once.with("GreenCloth", ">1").and_return(true)     
    Kernel.should_receive(:dependency).once.with("RedCloth", ">0.5").and_return(true)
    Kernel.dependencies "RedCloth" => ">0.5", "GreenCloth" => ">1"
    
  end
end

describe "Kernel#require" do

  before do
    @logger = StringIO.new
    Merb.logger = Merb::Logger.new(@logger)    
  end

  it "should be able to require and throw a useful error message" do
    Kernel.stub!(:require).with("redcloth").and_raise(LoadError)
    Merb.logger.should_receive(:error).with("foo")
    Kernel.rescue_require("redcloth", "foo")
  end
  
  it "should be able to require files and throw a VERY useful error message if it fails" do
    Kernel.should_receive(:require).and_raise(LoadError)
    Kernel.should_receive(:exit).and_return(true)
    Merb.logger.should_receive(:error).once.with(/Could not find/)
    Merb.logger.should_receive(:error).once.with(/Please be sure/)    
    Kernel.requires "foo"
  end

  it "should be able to require files and print a succeed message if it passes" do
    Kernel.should_receive(:require).and_return(true)
    Merb.logger.should_receive(:debug).with(/loading library 'foo'/)
    Kernel.requires "foo"
    
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

describe "Kernel misc." do
  it "should extract options from args" do
    args = ["foo", "bar", {:baz => :bar}]
    Kernel.extract_options_from_args!(args).should == {:baz => :bar}
    args.should == ["foo", "bar"]
  end
  
  it "should throw a useful error if there's no debugger" do
    Merb.logger.should_receive(:info).with "\n***** Debugger requested, but was not " + 
                        "available: Start server with --debugger " +
                        "to enable *****\n"
    Kernel.debugger
  end
end