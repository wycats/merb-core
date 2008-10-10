# Merb::Logger = Extlib::Logger

# ==== Public Merb Logger API
#
# To replace an existing logger with a new one:
#  Merb::Logger.set_log(log{String, IO},level{Symbol, String})
#
# Available logging levels are
#   Merb::Logger::{ Fatal, Error, Warn, Info, Debug }
#
# Logging via:
#   Merb.logger.fatal(message<String>,&block)
#   Merb.logger.error(message<String>,&block)
#   Merb.logger.warn(message<String>,&block)
#   Merb.logger.info(message<String>,&block)
#   Merb.logger.debug(message<String>,&block)
#
# Logging with autoflush:
#   Merb.logger.fatal!(message<String>,&block)
#   Merb.logger.error!(message<String>,&block)
#   Merb.logger.warn!(message<String>,&block)
#   Merb.logger.info!(message<String>,&block)
#   Merb.logger.debug!(message<String>,&block)
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
module Merb

  class Logger < Extlib::Logger

    # Appends a message to the log if the specified log level is at least as high as
    # the log level of the logger if Merb::Config[:verbose]. Then flushes the log 
    # buffer to disk.
    #
    # ==== Parameters
    # message<String>:: The message to be logged.
    # level<Symbol>:: The level at which to log. Default is :warn.
    #
    # ==== Returns
    # self:: The logger object for chaining.
    #
    # @api plugin
    def verbose!(message, level = :warn)
      send("#{level}!", message) if Merb::Config[:verbose]
    end

    # Appends a message to the log if the specified log level is at least as high as
    # the log level of the logger if Merb::Config[:verbose].
    #
    # ==== Parameters
    # message<String>:: The message to be logged.
    # level<Symbol>:: The level at which to log. Default is :warn.
    #
    # ==== Returns
    # self:: The logger object for chaining.
    #
    # @api plugin
    def verbose(message, level = :warn)
      send(level, message) if Merb::Config[:verbose]
    end

  end

end
