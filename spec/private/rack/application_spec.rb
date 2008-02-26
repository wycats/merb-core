require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require 'rack/mock'

Merb.start :environment => 'test'

describe Merb::Rack::Application do

  before do
    @app = Merb::Rack::Application.new
  end
  
  it "should return a MockResponse" do
    res = Rack::MockRequest.new(@app).get("")
    res.should be_kind_of Rack::MockResponse
  end
  
end  

describe Merb::Rack::Application, "with :path_prefix set" do

  before do 
    Merb::Config[:path_prefix] = "/quux"
    @app = Merb::Rack::Application.new
    @nullobj = mock('controller', :null_object => true)
  end
  
  it "should strip the path_prefix from a request's REQUEST_URI and PATH_INFO" do
    Merb::Dispatcher.should_receive(:handle).with(
      {'REQUEST_URI' => "/foo/bar", 'PATH_INFO' => "/foo/bar"}
    ).and_return @nullobj
    
    @app.call('REQUEST_URI' => "/quux/foo/bar", 'PATH_INFO' => "/quux/foo/bar")
  end

  it "should not leave REQUEST_URI or PATH_INFO empty" do
    Merb::Dispatcher.should_receive(:handle).with(
      {'REQUEST_URI' => "/", 'PATH_INFO' => "/"}
    ).and_return @nullobj
    
    @app.call('REQUEST_URI' => "/quux", 'PATH_INFO' => "/quux")
  end

end