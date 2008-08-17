require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

class RackyController < Merb::Controller
  def index
    body = "Everyone loves Rack"
    headers['Content-Length'] = body.size.to_s
    
    body
  end
end

Merb::Router.prepare do |r|
  r.match("/heavy/lifting").to(:controller => "racky_controller")
end

describe "rack application", :shared => true do
  it 'is callable' do
    @app.should respond_to(:call)
  end

  it 'returns a 3-tuple' do
    @result.size.should == 3
  end

  it 'returns status as first tuple element' do
    @result.first.should == 200
  end

  it 'returns hash of headers as the second tuple element' do
    @result[1].should be_an_instance_of(Hash)
  end

  it 'returns response body as third tuple element' do
    @result.last.should == @body
  end
end


describe Merb::Rack::Application do
  before(:each) do
    @app = Merb::Rack::Application.new
    @env = Rack::MockRequest.env_for('/heavy/lifting')
    
    @result = @app.call(@env)
    @body   = "Everyone loves Rack"
  end

  it_should_behave_like "rack application"

  describe "#deferred?" do
    it "returns true when request path matches deferred actions regexp" do
      Merb::Config[:deferred_actions] = ['/heavy/lifting']

      @app.deferred?(@env).should be(true)
    end

    it "returns false when request path DOES NOT match deferred actions regexp" do
      @app.deferred?(Rack::MockRequest.env_for('/not/deferred')).should be(false)
    end
  end
end


describe Merb::Rack::Middleware do
  before(:each) do
    @app = Merb::Rack::Application.new
    @middleware = Merb::Rack::Middleware.new(@app)
    @env        = Rack::MockRequest.env_for('/heavy/lifting')
    
    @result = @middleware.call(@env)
    @body   = "Everyone loves Rack"
  end

  it_should_behave_like "rack application"

  it "delegates request handling to wrapped Rack application" do
    @result.last.should == @body
  end

  describe "#deferred?" do
    it "is delegated to wrapped Rack application" do
      @middleware.deferred?(@env).should be(true)
      @middleware.deferred?(Rack::MockRequest.env_for('/not-deferred/')).should be(false)
    end
  end
end
