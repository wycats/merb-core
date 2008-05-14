require File.dirname(__FILE__) + '/spec_helper'

describe Merb::BootLoader::RackUpApplication do

  it "should default to rack config (rack.rb)" do
    options = {:merb_root => File.dirname(__FILE__) / 'fixture'}
    Merb::Config.setup(options)
    app = Merb::BootLoader::RackUpApplication.run
    app.class.should == Merb::Rack::Static
  end

  it "should use rackup config that we specified" do
    options = {:rackup => File.dirname(__FILE__) / 'fixture' / 'config' / 'black_hole.rb'}
    Merb::Config.setup(options)
    app = Merb::BootLoader::RackUpApplication.run
    app.class.should == Rack::Adapter::BlackHole

    env = Rack::MockRequest.env_for("/black_hole")
    status, header, body = app.call(env)
    status.should == 200
    header.should == { "Content-Type" => "text/plain" }
    body.should == ""
  end
end
