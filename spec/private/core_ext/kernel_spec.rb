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
    i = 0
    __caller_lines__(__caller_info__[0], __caller_info__[1], 4) { i += 1 }
    i.should == 9
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


describe "Kernel#load_dependency" do
  before :each do

  end

  it "DOES NOT add dependency to the list" do
    lambda {
      begin
        load_dependency("rspec", ">= 1.1.2")
      rescue LoadError => e
        # some people may have no RSpec gem
      end
    }.should_not change(Merb::BootLoader::Dependencies.dependencies, :size)
  end

  it "DOES NOT defer load to boot loader run and requires it right away" do
    self.should_receive(:require)

    begin
      load_dependency("rspec", ">= 1.1.2")
    rescue LoadError => e
      # some people may have no RSpec gem
    end
  end

  it "logs on events using info level" do
    self.should_receive(:require)
    Merb.logger.should_receive(:info!)

    begin
      load_dependency("rspec", ">= 1.1.2")
    rescue LoadError => e
      # some people may have no RSpec gem
    end
  end
end



describe "Kernel#dependencies" do
  it "deferres load of dependencies given as String" do
    self.should_receive(:dependency).with("hpricot").and_return(true)

    begin
      dependencies("hpricot")
    rescue LoadError => e
      # sanity check, should never happen
    end
  end

  it "deferres load of dependencies given as Array" do
    self.should_receive(:dependency).with("hpricot").and_return(true)
    self.should_receive(:dependency).with("rake").and_return(true)

    begin
      dependencies("hpricot", "rake")
    rescue LoadError => e
      # sanity check, should never happen
    end
  end

  it "deferres load of dependencies given as Hash" do
    self.should_receive(:dependency).with("hpricot", "0.6").and_return(true)
    self.should_receive(:dependency).with("rake", "0.8.1").and_return(true)

    begin
      dependencies("hpricot" => "0.6", "rake" => "0.8.1")
    rescue LoadError => e
      # sanity check, should never happen
    end
  end
end



describe "Kernel#load_dependencies" do
  it "loads dependencies given as String immediately" do
    self.should_receive(:load_dependency).with("hpricot").and_return(true)

    begin
      load_dependencies("hpricot")
    rescue LoadError => e
      # sanity check, should never happen
    end
  end

  it "loads dependencies given as Array immediately" do
    self.should_receive(:load_dependency).with("hpricot").and_return(true)
    self.should_receive(:load_dependency).with("rake").and_return(true)

    begin
      load_dependencies("hpricot", "rake")
    rescue LoadError => e
      # sanity check, should never happen
    end
  end

  it "loads dependencies given as Hash immediately" do
    self.should_receive(:load_dependency).with("hpricot", "0.6").and_return(true)
    self.should_receive(:load_dependency).with("rake", "0.8.1").and_return(true)

    begin
      load_dependencies("hpricot" => "0.6", "rake" => "0.8.1")
    rescue LoadError => e
      # sanity check, should never happen
    end
  end
end
