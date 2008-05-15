require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb do

  describe "Command Line Options" do
    
    it "should allow -l / --log_level to set the log_level" do
      pending("How do we spec these?")
    end
    
    it "should allow -L / --log_file  to set the log_file" do
      pending("How do we spec these?")
      # Run an instance of merb from the command line 
      # using system and test if the file was created?
    end
    
  end

end

describe Merb::Logger do

  describe "#new" do
    it "should call set_log with the arguments it was passed." do
      logger = Merb::Logger.allocate # create an object sans initialization
      logger.should_receive(:set_log).with('a partridge', 'a pear tree', 'a time bomb').and_return(true)
      logger.send(:initialize, 'a partridge', 'a pear tree', 'a time bomb')
    end
  end
  
  describe "#set_log" do

    before(:each) do
      @logger = Merb::Logger.new(Merb.log_file)
    end

    it "should set the log level to :warn (4) when second parameter is :warn" do
      Merb::Logger.new(Merb.log_file, :warn).level.should eql(4)
    end

    it "should set the log level to :debug (0) when Merb.environment is development" do
      Merb.should_receive(:environment).and_return("development")
      @logger.set_log(Merb.log_path / "development.log")
      @logger.level.should eql(0)
    end
    
    it "should set the log level to :error (6) when Merb.environment is production" do
      Merb.should_receive(:environment).and_return("production")
      @logger.set_log(Merb.log_path / "production.log")
      @logger.level.should eql(4)
    end
    
    it "should initialize the buffer to an empty array" do
      @logger.buffer.should eql([])
    end

    it "should default the delimiter to ' ~ '" do
      @logger.delimiter.should eql(" ~ ")
    end
    
    it "should assign the newly created object to Merb.logger" do
      @logger = Merb::Logger.new(Merb.log_file)
      Merb.logger.should eql(@logger)
    end
    
  end
  
  describe "#flush" do

    before(:each) do
      @logger = Merb::Logger.new(Merb.log_file)
    end
    
    it "should immediately return if the buffer is empty" do
      @logger.should_not_receive(:write)
      @logger.flush
    end

    it "should call the write_method with the stringified contents of the buffer if the buffer is non-empty" do
      @logger.send(:<<, "a message")
      @logger.send(:<<, "another message")
      @logger.log.should_receive(:write).with(" ~ a message\n ~ another message\n")
      @logger.flush
    end

  end
  
  describe "#close" do
    before(:each) do
      @logger = Merb::Logger.new(Merb.log_file)
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

    it "shouldn't call the close method if the log is a terminal" do
      @logger.log.should_receive(:tty?).and_return(true)
      @logger.log.should_not_receive(:close)
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
      @logger = Merb::Logger.new(Merb.log_file)
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
