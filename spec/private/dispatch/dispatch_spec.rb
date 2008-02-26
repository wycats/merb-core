require File.join(File.dirname(__FILE__), "spec_helper")
require 'rack/mock'
require 'stringio'
Merb.start :environment => 'test', 
           :merb_root => File.dirname(__FILE__) / 'fixture'

describe Merb::Dispatcher do

  it "should handle return an Exceptions controller for a bad route request" do
    env = Rack::MockRequest.env_for("/notreal")
    Merb::Dispatcher.handle(env).should be_kind_of(Exceptions)
  end
  
  it "should search for an action matching the specific exception in the Exceptions controller" do
    env = Rack::MockRequest.env_for("/foo/raise_not_acceptable")
    env['REQUEST_URI'] = '/foo/raise_not_acceptable'
    Merb::Dispatcher.handle(env).action_name.should == 'not_acceptable'
  end
  
  it "should search for actions matching more general exception types if the specific one cannot be found in the Exception controller" do
    env = Rack::MockRequest.env_for("/foo/raise_conflict")
    env['REQUEST_URI'] = '/foo/raise_conflict'
    Merb::Dispatcher.handle(env).action_name.should == 'client_error'
  end
    
end