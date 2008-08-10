require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::Controller, " redirects" do
  it "redirects with simple URLs" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::SimpleRedirect, :index)
    @controller.status.should == 302
    @controller.headers["Location"].should == "/"
  end

  it "permanently redirects" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::PermanentRedirect, :index)
    @controller.status.should == 301
    @controller.headers["Location"].should == "/"
  end

  it "redirects with messages" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::RedirectWithMessage, :index)
    @controller.status.should == 302
    expected_url = Merb::Request.escape([Marshal.dump(:notice => "what?")].pack("m"))
    @controller.headers["Location"].should == "/?_message=#{expected_url}"
  end
  
  it "consumes redirects with messages" do
    message = Merb::Request.escape([Marshal.dump(:notice => "what?")].pack("m"))
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConsumesMessage, :index, {:_message => message})
    @controller.body.should == "\"what?\""
  end
  
  it "supports setting the message for use immediately" do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::SetsMessage, :index)
    @controller.body.should == "Hello"
  end
end