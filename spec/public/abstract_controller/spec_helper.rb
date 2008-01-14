require 'rubygems'
require 'ruby-debug'
__DIR__ = File.dirname(__FILE__)

require File.join(__DIR__, "..", "..", "spec_helper")

# The framework structure *must* be set up before loading in framework
# files.
Merb.push_path(:layout, __DIR__ / "controllers" / "views" / "layouts")
require File.join(__DIR__, "controllers", "filters")
require File.join(__DIR__, "controllers", "render")

Merb::BootLoader::Templates.new.run

module Merb::Test::Behaviors
  
  def dispatch_should_make_body(klass, body, action = :index)
    controller = Merb::Test::Fixtures.const_get(klass).new
    controller._dispatch(action)
    controller._body.should == body
  end
end

Spec::Runner.configure do |config|
  config.include Merb::Test::Behaviors
end