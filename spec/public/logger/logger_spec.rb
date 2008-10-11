require File.join(File.dirname(__FILE__), "spec_helper")
startup_merb

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
      Merb.reset_logger!
      Merb.logger.level.should == 4
    end

    it "should set the log level to :debug (0) when Merb.environment is development" do
      Merb.environment = "development"
      Merb::Config.delete(:log_level)
      Merb.reset_logger!
      Merb::BootLoader::Logger.run
      Merb.logger.level.should == 0
    end

    it "should set the log level to :error (6) when Merb.environment is production" do
      Merb.environment = "production"
      Merb::Config.delete(:log_level)
      Merb.reset_logger!
      Merb::BootLoader::Logger.run
      Merb.logger.level.should == 4
    end

    it "should default the delimiter to ' ~ '" do
      Merb.logger.delimiter.should eql(" ~ ")
    end

    it 'allows level value be specified as a String' do
      Merb::Config[:log_level] = 'warn'
      Merb.reset_logger!
      Merb.logger.level.should == 4
    end
  end


  describe "#flush" do
    it "should immediately return if the buffer is empty" do
      Merb::Config[:log_stream] = StringIO.new
      Merb.reset_logger!

      Merb.logger.flush
      Merb::Config[:log_stream].string.should == ""
    end

    it "should call the write_method with the stringified contents of the buffer if the buffer is non-empty" do
      Merb::Config[:log_stream] = StringIO.new
      Merb.reset_logger!

      Merb.logger << "a message"
      Merb.logger << "another message"
      Merb.logger.flush

      Merb::Config[:log_stream].string.should == " ~ a message\n ~ another message\n"
    end

  end

  # There were close specs here, but the logger isn't an IO anymore, and
  # shares a stream with other loggers, so it shouldn't be closing the
  # stream.

  def set_level(level)
    Merb::Config[:log_level] = level
    Merb.reset_logger!
  end

  # Spec examples below all use log_with_method
  # matcher that is defined right here.
  Spec::Matchers.create(:log_with_method) do
    # logger is received, method is matcher argument
    # So if you call Merb.logger.should log_with_method(:info),
    # logger has value of Merb.logger and method has value of :info.
    matches do |logger, method|
      logger.send(method, "message")
      logger.flush

      logger.log.string == " ~ message\n"
    end

    message do |logger, method|
      "Expected #{logger} NOT to log with method #{method}, but it did."
    end

    failure_message do |logger, method|
      "Expected #{logger} to log with method #{method}, but it did not."
    end
  end

  describe "#debug" do
    before(:each) do
      @stream = Merb::Config[:log_stream] = StringIO.new
    end

    it "adds to the buffer with debug level" do
      set_level(:debug)
      Merb.logger.should log_with_method(:debug)
    end

    it "does not add to the buffer with info level" do
      set_level(:info)
      Merb.logger.should_not log_with_method(:debug)
    end

    it "does not add to the buffer with warn level" do
      set_level(:warn)
      Merb.logger.should_not log_with_method(:debug)
    end

    it "does not add to the buffer with error level" do
      set_level(:error)
      Merb.logger.should_not log_with_method(:debug)
    end

    it "does not add to the buffer with fatal level" do
      set_level(:fatal)
      Merb.logger.should_not log_with_method(:debug)
    end
  end # #debug


  describe "#info" do
    before(:each) do
      @stream = Merb::Config[:log_stream] = StringIO.new
    end

    it "adds to the buffer with debug level" do
      set_level(:debug)
      Merb.logger.should log_with_method(:info)
    end

    it "adds to the buffer with info level" do
      set_level(:info)
      Merb.logger.should log_with_method(:info)
    end

    it "does not add to the buffer with warn level" do
      set_level(:warn)
      Merb.logger.should_not log_with_method(:info)
    end

    it "does not add to the buffer with error level" do
      set_level(:error)
      Merb.logger.should_not log_with_method(:info)
    end

    it "does not add to the buffer with fatal level" do
      set_level(:fatal)
      Merb.logger.should_not log_with_method(:info)
    end
  end # #info


  describe "#warn" do
    before(:each) do
      @stream = Merb::Config[:log_stream] = StringIO.new
    end

    it "adds to the buffer with debug level" do
      set_level(:debug)
      Merb.logger.should log_with_method(:warn)
    end

    it "adds to the buffer with info level" do
      set_level(:info)
      Merb.logger.should log_with_method(:warn)
    end

    it "adds to the buffer with warn level" do
      set_level(:warn)
      Merb.logger.should log_with_method(:warn)
    end

    it "does not add to the buffer with error level" do
      set_level(:error)
      Merb.logger.should_not log_with_method(:warn)
    end

    it "does not add to the buffer with fatal level" do
      set_level(:fatal)
      Merb.logger.should_not log_with_method(:warn)
    end
  end # #warn


  describe "#error" do
    before(:each) do
      @stream = Merb::Config[:log_stream] = StringIO.new
    end

    it "adds to the buffer with debug level" do
      set_level(:debug)
      Merb.logger.should log_with_method(:error)
    end

    it "adds to the buffer with info level" do
      set_level(:info)
      Merb.logger.should log_with_method(:error)
    end

    it "adds to the buffer with warn level" do
      set_level(:warn)
      Merb.logger.should log_with_method(:error)
    end

    it "adds to the buffer with error level" do
      set_level(:error)
      Merb.logger.should log_with_method(:error)
    end

    it "does not add to the buffer with fatal level" do
      set_level(:fatal)
      Merb.logger.should_not log_with_method(:error)
    end
  end # #error


  describe "#fatal" do
    before(:each) do
      @stream = Merb::Config[:log_stream] = StringIO.new
    end

    it "adds to the buffer with debug level" do
      set_level(:debug)
      Merb.logger.should log_with_method(:fatal)
    end

    it "adds to the buffer with info level" do
      set_level(:info)
      Merb.logger.should log_with_method(:fatal)
    end

    it "adds to the buffer with warn level" do
      set_level(:warn)
      Merb.logger.should log_with_method(:fatal)
    end

    it "adds to the buffer with error level" do
      set_level(:error)
      Merb.logger.should log_with_method(:fatal)
    end

    it "adds to the buffer with fatal level" do
      set_level(:fatal)
      Merb.logger.should log_with_method(:fatal)
    end
  end # #fatal
end # Merb::Logger
