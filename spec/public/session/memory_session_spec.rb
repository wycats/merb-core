$START_OPTIONS = { :session_store => "memory" }

require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "session_spec")
require File.join(File.dirname(__FILE__), "controllers", "sessions")

describe Merb::MemorySession do
  
  before do 
    @session_class = Merb::MemorySession
    @session = @session_class.generate
  end
  
  it_should_behave_like "All session-store backends"
  
  it "should have a session_store_type class attribute" do
    @session.class.session_store_type.should == :memory
  end
  
end

describe Merb::MemorySession, "mixed into Merb::Controller" do

  before(:all) { @session_class = Merb::MemorySession }
  
  it_should_behave_like "All session-stores mixed into Merb::Controller"

end