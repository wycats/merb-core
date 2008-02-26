__DIR__ = File.dirname(__FILE__)
require File.join(__DIR__, "..", "..", "spec_helper")

require File.join(__DIR__, "controllers", "filters")
require File.join(__DIR__, "controllers", "render")
require File.join(__DIR__, "controllers", "partial")
require File.join(__DIR__, "controllers", "display")
require File.join(__DIR__, "controllers", "helpers")

Merb.start :environment => 'test'

module Merb::Test::Behaviors
  include Merb::Test::RequestHelper
  
  def dispatch_should_make_body(klass, body, action = :index, opts = {})
    controller = Merb::Test::Fixtures::Abstract.const_get(klass).new
    if opts.key?(:presets)
      opts[:presets].each { |attr, value| controller.send(attr, value)}
    end
    controller._dispatch(action.to_s)
    controller.body.should == body
  end
end

Spec::Runner.configure do |config|
  config.include Merb::Test::Behaviors
end