__DIR__ = File.dirname(__FILE__)

require File.join(__DIR__, "..", "..", "spec_helper")

require File.join(__DIR__, "controllers", "base")
require File.join(__DIR__, "controllers", "responder")
require File.join(__DIR__, "controllers", "display")

Merb.start :environment => 'test'