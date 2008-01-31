require File.join(File.dirname(__FILE__), "spec_helper")

Merb.environment = "development" # Temporary hack-fix to nil environment default bug

describe Merb::Logger do

  describe "#new" do
    it "should call set_log with the arguments it was passed."
    # do
    #  Merb::Logger.new("merb_test.log").should_receive(:set_log).with("merb_test.log").and_return(true)
    #end
  end
  
  describe "#set_log" do

    before(:each) do
      @logger = Merb::Logger.new("merb_test.log")
    end

    it "should set the log level to '4' when second parameter is :warn" do
      Merb::Logger.new("merb_test.log", :warn).level.should eql(4)
    end

    it "should set the log level to :debug (0) when Merb.environment is development" do
      Merb.should_receive(:environment).twice.and_return("development")
      @logger.set_log("merb_test2.log")
      @logger.level.should == 0
    end
    
    it "should set the log level to :error (6) when Merb.environment is production" do
      Merb.should_receive(:environment).twice.and_return("production")
      @logger.set_log("merb_test2.log")
      @logger.level.should == 6
    end
    
    it "should initialize the buffer to an empty array" do
      @logger.buffer.should eql([])
    end

    it "should default the delimiter to ' ~ '" do
      @logger.delimiter.should eql(" ~ ")
    end
    
    it "should assign the newly created object to Merb.logger"
    
  end
  
  describe "#flush" do

    before(:each) do
      @logger = Merb::Logger.new("merb_test.log")
    end
    
    it "should immediately return if the buffer is empty" do
      @logger.should_not_receive(:write_method)
      @logger.flush
    end

    it "should call the write_method with the stringified contents of the buffer if the buffer is non-empty" do
      now = Time.now
      Time.stub!(:now).and_return(now)
      @logger.send(:<<, "a message")
      @logger.send(:<<, "another message")
      @logger.log.should_receive(:write_method).with("#{now.httpdate} ~ a message\n#{now.httpdate} ~ another message\n")
      @logger.flush
    end

  end
  
  describe "#close" do
    before(:each) do
      @logger = Merb::Logger.new("merb_test.log")
    end

    it "should flush the buffer before closing" do
      # TODO: how to specify order? eg. flush then close
      @logger.should_receive(:flush)
      @logger.log.should_receive(:close)
      @logger.close
    end

    it "should call the close method if the log responds to close" do
      @logger.log.should_receive(:close)
      @logger.close
    end

    it "should set the stored log attribute to nil" do
      @logger.close
      @logger.log.should eql(nil)
    end

  end

  describe "<<" do
    
  end

  describe "level methods" do

    before(:all) do
      @logger = Merb::Logger.new("merb_test.log")
    end

    it "should provide a #debug method which can be used to log" do
      @logger.should respond_to(:debug)
      @logger.should_receive(:<<).with("message").and_return(true)
      @logger.debug("message")
    end

    it "should provide a #info method which can be used to log" do
      @logger.should respond_to(:info)
      @logger.should_receive(:<<).with("message").and_return(true)
      @logger.info("message")
    end

    it "should provide a #warn method which can be used to log" do
      @logger.should respond_to(:warn)
      @logger.should_receive(:<<).with("message").and_return(true)
      @logger.warn("message")
    end

    it "should provide a #error method which can be used to log" do
      @logger.should respond_to(:error)
      @logger.should_receive(:<<).with("message").and_return(true)
      @logger.error("message")
    end

    it "should provide a #fatal method which can be used to log" do
      @logger.should respond_to(:fatal)
      @logger.should_receive(:<<).with("message").and_return(true)
      @logger.fatal("message")
    end
    
    # TODO: add positive and negative tests for each of the methods below:
    it "should provide a #debug? method" do
      @logger.should respond_to(:debug?)
    end

    it "should provide a #info? method" do
      @logger.should respond_to(:info?)
    end

    it "should provide a #warn? method" do
      @logger.should respond_to(:warn?)
    end

    it "should provide a #error? method" do
      @logger.should respond_to(:error?)
    end

    it "should provide a #fatal? method" do
      @logger.should respond_to(:fatal?)
    end

  end

end
