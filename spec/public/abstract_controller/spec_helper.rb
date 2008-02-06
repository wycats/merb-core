__DIR__ = File.dirname(__FILE__)
require File.join(__DIR__, "..", "..", "spec_helper")

require File.join(__DIR__, "controllers", "filters")
require File.join(__DIR__, "controllers", "render")
require File.join(__DIR__, "controllers", "partial")
require File.join(__DIR__, "controllers", "display")

Merb.start :environment => 'test', :adapter =>  'runner'

module Merb::Test::Behaviors
  
  def dispatch_should_make_body(klass, body, action = :index)
    controller = Merb::Test::Fixtures::Abstract.const_get(klass).new
    controller._dispatch(action.to_s)
    controller.body.should == body
  end
end

Spec::Runner.configure do |config|
  config.include Merb::Test::Behaviors
end