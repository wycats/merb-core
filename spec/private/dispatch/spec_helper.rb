require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

Spec::Runner.configure do |config|
  config.include Merb::Test::RequestHelper
end