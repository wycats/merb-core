__DIR__ = File.dirname(__FILE__)
require 'ruby-debug'

require File.join(__DIR__, "..", "..", "spec_helper")

require File.join(__DIR__, "controllers", "base")
require File.join(__DIR__, "controllers", "responder")

Merb::BootLoader::Templates.run
Merb::BootLoader::MimeTypes.run