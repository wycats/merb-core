require File.join(File.dirname(__FILE__), "spec_helper")
require 'rack/mock'
require 'stringio'
Merb.start :environment => 'test', 
           :merb_root => File.dirname(__FILE__) / 'fixture'

describe Merb::Dispatcher, "route params" do
  before(:each) do
    env = Rack::MockRequest.env_for("/foo/bar/54")
    env['REQUEST_URI'] = "/foo/bar/54"  # MockRequest doesn't set this
    @controller = Merb::Dispatcher.handle(env)
  end

  it "should properly set the route params" do
    @controller.request.route_params[:id].should == '54'
  end

  it "should properly add route_params to params" do
    @controller.request.route_params.each { |k,v|
      @controller.request.params[k].should == v
    }
  end

end