require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require 'rack/mock'

describe Merb::Rack::Application do

  before do
    @app = Merb::Rack::Application.new
  end
  
  it "should return a MockResponse" do
    res = Rack::MockRequest.new(@app).get("")
    res.should be_kind_of Rack::MockResponse
  end
  
end  