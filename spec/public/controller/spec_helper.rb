__DIR__ = File.dirname(__FILE__)

require File.join(__DIR__, "..", "..", "spec_helper")

require File.join(__DIR__, "controllers", "base")
require File.join(__DIR__, "controllers", "responder")
require File.join(__DIR__, "controllers", "display")
require File.join(__DIR__, "controllers", "authentication")
require File.join(__DIR__, "controllers", "redirect")
require File.join(__DIR__, "controllers", "cookies")
require File.join(__DIR__, "controllers", "conditional_get")

Merb.start :environment => 'test', :init_file => File.join(__DIR__, 'config', 'init')
