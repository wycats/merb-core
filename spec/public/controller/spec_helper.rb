__DIR__ = File.dirname(__FILE__)

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
startup_merb

require File.join(__DIR__, "controllers", "base")
require File.join(__DIR__, "controllers", "responder")
require File.join(__DIR__, "controllers", "display")
require File.join(__DIR__, "controllers", "authentication")
require File.join(__DIR__, "controllers", "redirect")
require File.join(__DIR__, "controllers", "cookies")
require File.join(__DIR__, "controllers", "conditional_get")
require File.join(__DIR__, "controllers", "streaming")

Merb.start :environment => 'test', :init_file => File.join(__DIR__, 'config', 'init')
