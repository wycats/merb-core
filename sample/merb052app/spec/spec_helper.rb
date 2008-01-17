$TESTING=true
require File.join(File.dirname(__FILE__), "..", 'config', 'boot')
Merb.environment="test"
require File.join(Merb.root, 'config', 'merb_init')

require 'merb/test/helper'
require 'merb/test/rspec'

Spec::Runner.configure do |config|
    config.include(Merb::Test::Helper)
    config.include(Merb::Test::RspecMatchers)
end


### METHODS BELOW THIS LINE SHOULD BE EXTRACTED TO MERB ITSELF
