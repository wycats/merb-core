$TESTING=true
require 'timeout'
require 'open-uri'
require 'net/http'
require 'rubygems'
require 'spec'
require 'mocha'
require 'hpricot'
$:.push File.join(File.dirname(__FILE__), '..', 'lib')
$:.push File.join(File.dirname(__FILE__), '..', 'lib', 'merb', 'server')
require File.join(File.dirname(__FILE__), '..', 'lib', 'merb', 'config')
Merb::Config.setup
require 'merb'
require 'merb/test/helper'

FIXTURES = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures')) unless defined?(FIXTURES)

require File.join(File.dirname(__FILE__), "spec_helpers", "url_shared_behaviour")

Spec::Runner.configure do |config|
  config.include(Merb::Test::Helper)
  config.include(Merb::Test::RspecMatchers)
  # config.include(Merb::Test::MerbRspecControllerRedirect)
end

# Creates a new controller, e.g.
#   c = new_controller('index', Examples) do |request|
#     request.post_body = "blah"
#   end
def new_controller(action = 'index', controller = nil, additional_params = {})
  request = OpenStruct.new
  request.params = {:action => action, :controller => (controller.to_s || "Test")}
  request.params.update(additional_params)
  request.cookies = {}
  request.accept ||= '*/*'
  
  yield request if block_given?
  
  response = OpenStruct.new
  response.read = ""
  (controller || Merb::Controller).build(request, response)
end

class Merb::Controller
  require "lib/merb/session/memory_session"
  Merb::MemorySessionContainer.setup
  include ::Merb::SessionMixin
  self.session_secret_key = "footo the bar to the baz"
end

class String
  def clean
    Hpricot(chomp).to_s
  end
end


# -- Global custom matchers --

# A better +be_kind_of+ with more informative error messages.
#
# The default +be_kind_of+ just says 
#
#   "expected to return true but got false"
#
# This one says
#
#   "expected File but got Tempfile"

class BeKindOf
  
  def initialize(expected) # + args
    @expected = expected
  end

  def matches?(target)
    @target = target
    @target.kind_of?(@expected)
  end

  def failure_message
    "expected #{@expected} but got #{@target.class}"
  end

  def negative_failure_message
    "expected #{@expected} to not be #{@target.class}"
  end

  def description
    "be_kind_of #{@target}"
  end

end

def be_kind_of(expected) # + args
  BeKindOf.new(expected)
end