require File.join(File.dirname(__FILE__), "spec_helper")
require 'rack/mock'
require 'stringio'
Merb.start :environment => 'test', 
           :adapter =>  'runner', 
           :merb_root => File.dirname(__FILE__) / 'fixture'

describe Merb::Dispatcher do

  it "should handle return an Exceptions controller for a bad route request" do
    env = Rack::MockRequest.env_for("/notreal")
    Merb::Dispatcher.handle(env, StringIO.new).should be_kind_of Exceptions
  end

end