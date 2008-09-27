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
      # @logger = Merb::Logger.new(Merb.log_file)
    end

    it "should set the log level to :warn (4) when second parameter is :warn" do
      Merb::Config[:log_level] = :warn
      Merb.logger = nil
      Merb.logger.level.should == 4
    end

    it "should set the log level to :debug (0) when Merb.environment is development" do
      Merb.environment = "development"
      Merb::Config.delete(:log_level)
      Merb.logger = nil
      Merb::BootLoader::Logger.run
      Merb.logger.level.should == 0
    end
    
    it "should set the log level to :error (6) when Merb.environment is production" do
      Merb.environment = "production"
      Merb::Config.delete(:log_level)
      Merb.logger = nil
      Merb::BootLoader::Logger.run
      Merb.logger.level.should == 4
    end
    
    it "should default the delimiter to ' ~ '" do
      Merb.logger.delimiter.should eql(" ~ ")
    end    
    
  end
  
  describe "#flush" do

    it "should immediately return if the buffer is empty" do
      Merb::Config[:log_stream] = StringIO.new
      Merb.logger = nil
      
      Merb.logger.flush
      Merb::Config[:log_stream].string.should == ""
    end

    it "should call the write_method with the stringified contents of the buffer if the buffer is non-empty" do
      Merb::Config[:log_stream] = StringIO.new
      Merb.logger = nil
      
      Merb.logger << "a message"
      Merb.logger << "another message"
      Merb.logger.flush
      
      Merb::Config[:log_stream].string.should == " ~ a message\n ~ another message\n"
    end

  end
  
  # There were close specs here, but the logger isn't an IO anymore, and
  # shares a stream with other loggers, so it shouldn't be closing the
  # stream.

  describe "level methods" do

    def set_level(level)
      Merb::Config[:log_level] = level
      Merb.logger = nil
    end

    before(:each) do
      @stream = Merb::Config[:log_stream] = StringIO.new
    end

    it "should provide a #debug method which adds to the buffer in level :debug" do
      set_level(:debug)
      Merb.logger.debug("message")
      Merb.logger.flush
      @stream.string.should == " ~ message\n"
    end

    it "should provide a #debug method which does not add to the buffer " \
      "in level :info or higher" do
      set_level(:info)
      Merb.logger.debug("message")
      Merb.logger.flush
      @stream.string.should == ""
    end
    
    it "should provide an #info method which adds to the buffer in " \
      "level :info or below" do
      set_level(:info)
      Merb.logger.info("message")
      Merb.logger.flush
      @stream.string.should == " ~ message\n"
    end

    it "should provide a #info method which does not add to the buffer " \
      "in level :warn or higher" do
      set_level(:warn)
      Merb.logger.info("message")
      Merb.logger.flush
      @stream.string.should == ""
    end

    it "should provide a #warn method which adds to the buffer in " \
      "level :warn or below" do
      set_level(:warn)
      Merb.logger.warn("message")
      Merb.logger.flush
      @stream.string.should == " ~ message\n"
    end

    it "should provide a #warn method which does not add to the buffer " \
      "in level :error or higher" do
      set_level(:error)
      Merb.logger.warn("message")
      Merb.logger.flush
      @stream.string.should == ""
    end

    it "should provide a #error method which adds to the buffer in " \
      "level :error or below" do
      set_level(:error)
      Merb.logger.error("message")
      Merb.logger.flush
      @stream.string.should == " ~ message\n"
    end

    it "should provide a #error method which does not add to the buffer " \
      "in level :fatal or higher" do
      set_level(:fatal)
      Merb.logger.error("message")
      Merb.logger.flush
      @stream.string.should == ""
    end

    it "should provide a #fatal method which always logs" do
      set_level(:fatal)
      Merb.logger.fatal("message")
      Merb.logger.flush
      @stream.string.should == " ~ message\n"
    end
    
    # TODO: add positive and negative tests for each of the methods below:
    it "should provide a #debug? method" do
      Merb.logger.should respond_to(:debug?)
    end

    it "should provide a #info? method" do
      Merb.logger.should respond_to(:info?)
    end

    it "should provide a #warn? method" do
      Merb.logger.should respond_to(:warn?)
    end

    it "should provide a #error? method" do
      Merb.logger.should respond_to(:error?)
    end

    it "should provide a #fatal? method" do
      Merb.logger.should respond_to(:fatal?)
    end

  end

end
