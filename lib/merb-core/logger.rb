# ==== Public Merb Logger API
#
# To replace an existing logger with a new one:
#  Merb::Logger.set_log(log{String, IO},level{Symbol, String})
#
# Available logging levels are
#   Merb::Logger::{ Emergency, Alert, Critical, Error, Warning, Notice, Info, Debug }
#
# Logging via:
#   Merb.logger.info(message<string>,&block)
#   Merb.logger.emergency(message<string>)
#   Merb.logger.alert(message<string>)
#   Merb.logger.critical(message<string>)
#   Merb.logger.error(message<string>)
#   Merb.logger.warning(message<string>)
#   Merb.logger.notice(message<string>)
#   Merb.logger.info(message<string>)
#   Merb.logger.debug(message<string>)
#
# Flush the buffer to 
#   Merb.logger.flush
#
# Remove the current log object
#   Merb.logger.close
# 
# ==== Private Merb Logger API
# 
# To initialize the logger you create a new object, proxies to set_log.
#   Merb::Logger.new(log{String, IO},level{Symbol, String})
#
module Merb
  
  class << self #:nodoc:
    attr_accessor :logger
  end
  
  class Logger
    attr_accessor :aio
    attr_accessor :level
    attr_accessor :delimiter

    attr_reader :buffer

    Emergency, Alert, Critical, Error, Warning, Notice, Info, Debug = 0, 1, 2, 3, 4, 5, 6, 7
    Levels = [ :emergency, :alert, :critical, :error, :warning, :notice, :info, :debug ]
    
    # To initialize the logger you create a new object, proxies to set_log.
    #   Merb::Logger.new(log{String, IO},level{Symbol, String})
    #
    # ==== Parameters
    # log<IO,String>
    #   Either an IO object or a name of a logfile.
    # log_level<String>
    #   The string message to be logged
    # delimiter<String>
    #   Delimiter to use between message sections
    def initialize(*args)
      set_log(*args)
    end
    
    # To replace an existing logger with a new one:
    #  Merb::Logger.set_log(log{String, IO},level{Symbol, String})
    # 
    # ==== Parameters
    # log<IO,String>
    #   Either an IO object or a name of a logfile.
    # log_level<String>
    #   The string message to be logged
    # delimiter<String>
    #   Delimiter to use between message sections
    def set_log(log, log_level = Debug, delimiter = " ~ ")
      @level, @buffer, @aio, @delimiter = log_level, [], false, delimiter

      close if @log # be sure that we don't leave open files laying around.

      if log.respond_to?(:write)
        @log = log
        @log.sync if log.respond_to?(:sync)
      elsif File.exist?(log)
        @log = open(log, (File::WRONLY | File::APPEND))
        @log.sync = true
      else
        FileUtils.mkdir_p(File.dirname(log)) unless File.exist?(File.dirname(log))
        @log = open(log, (File::WRONLY | File::APPEND | File::CREAT))
        @log.sync = true
        # Question: Should we creat a logfile delimiter that people can set? 
        # (to be able to custom replace the '|')
        @log.write("#{Time.now.httpdate} #{delimiter} info #{delimiter} Logfile created\n")
      end

      if !Merb.environment.match(/development|test/) && 
         !RUBY_PLATFORM.match(/java|mswin/) &&
         !(@log == STDOUT) &&
          @log.respond_to?(:write_nonblock)
        @aio = true
      end
      
      # The idea here is that instead of performing an 'if' conditional check
      # on each logging we do it once when the log object is setup
      undef write_method if defined? write_method
      if aio
        alias :write_method :write_nonblock
      else
        alias :write_method :write
      end

      Merb.logger = self
    end
    
    # Flush the entire buffer to the log object.
    #   Merb.logger.flush
    # ==== Parameters
    # none
    def flush
      unless @buffer.size == 0
        @log.write_method(@buffer.slice!(0..-1).to_s) unless @buffer.size == 0
      end
    end
    
    # Close and remove the current log object.
    #   Merb.logger.close
    # ==== Parameters
    # none
    def close
      flush
      @log.close if @log.respond_to?(:close)
      @log = nil
    end
    
    # Generate the following logging methods for Merb.logger:
    #
    #   Merb.logger.info(message<string>, &block)
    #   Merb.logger.emergency(message<string>, &block)
    #   Merb.logger.alert(message<string>, &block)
    #   Merb.logger.critical(message<string>, &block)
    #   Merb.logger.error(message<string>, &block)
    #   Merb.logger.warning(message<string>, &block)
    #   Merb.logger.notice(message<string>, &block)
    #   Merb.logger.info(message<string>, &block)
    #   Merb.logger.debug(message<string>, &block)
    Levels.each_with_index do |level,index|
      class_eval <<-LEVELMETHODS
        def #{level}(message = nil, &block)
          buffer(#{index}, message, &block)
        end
        
        def #{level}?
          #{index} >= @level
        end
      LEVELMETHODS
    end

    private
    
    # Appends a string and log level to logger's buffer. 
    # Note that the string is discarded if the string's log level less than the logger's log level. 
    # Note that if the logger is aio capable then the logger will use non-blocking asynchronous writes.
    #
    # ==== Parameters
    # level<Fixnum>
    #   The logging level as an integer
    # string<String>
    #   The string message to be logged
    # block<&block>
    #   An optional block that will be evaluated and added to the logging message after the string message.
    def buffer(log_level, string = nil)
      return if level > log_level
      message = Time.now.httpdate
      message << delimiter
      message << string if string
      if block_given?
        message << delimiter
        message << yield
      end
      message << "\n" unless message[-1] == ?\n
      @buffer << message
      message
    end
    
  end
  
  # Convenience wrapper for logging, allows us to use:
  #   Merb.log(:info, "message", &block)
  #
  # ==== Parameters
  # *args<Object>
  #   : expected are log_level and a string message, with an optional block
  def self.log(*args, &block)
    # If no logger has been defined yet at this point, log to STDOUT.
    self.logger ||= Merb::Logger.new(STDOUT, :debug)
    self.logger.send(*args, &block)
  end
  
end
