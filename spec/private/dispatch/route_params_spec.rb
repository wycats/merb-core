$START_OPTIONS = {:merb_root => File.join(File.dirname(__FILE__), "fixture")}
require File.join(File.dirname(__FILE__), "spec_helper")
require 'rack/mock'
require 'stringio'

describe Merb::Dispatcher, "route params" do
  before(:each) do
    Merb::Router.prepare do |r|
      r.default_routes
    end

    @controller = Merb::Dispatcher.handle(Merb::Request.new(env_for("/tickets/book/milan")))    
  end

  def env_for(path)
    env = Rack::MockRequest.env_for(path)
    env['REQUEST_URI'] = path  # MockRequest doesn't set this

    env
  end

  it "should properly set the route parameters" do
    @controller.request.route_params[:id].should == 'milan'
    @controller.request.route_params[:action].should == 'book'
    @controller.request.route_params[:controller].should == 'tickets'

    @controller = Merb::Dispatcher.handle(Merb::Request.new(env_for("/products/show/54")))
    
    @controller.request.route_params[:id].should == '54'
    @controller.request.route_params[:action].should == 'show'
    @controller.request.route_params[:controller].should == 'products'
  end

  it "should properly add route_params to params" do
    @controller.request.route_params.each { |k,v|
      @controller.request.params[k].should == v
    }
  end

end
