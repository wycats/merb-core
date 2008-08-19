$START_OPTIONS = { :session_store => "cookie" }

require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "session_spec")
require File.join(File.dirname(__FILE__), "controllers", "sessions")

require "merb-core/dispatch/session/cookie"

describe Merb::CookieSession do
  
  before do 
    @session_class = Merb::CookieSession
    @session = @session_class.generate
  end
  
  it_should_behave_like "All session-store backends"
  
end

describe Merb::CookieSession, "mixed into Merb::Controller" do
  
  before(:all) do
    @session_class = Merb::CookieSession
    @session = @session_class.generate
  end
  
  it_should_behave_like "All session-stores mixed into Merb::Controller"
  
end