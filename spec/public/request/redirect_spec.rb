require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

describe Merb::Request, " redirects" do
  it "redirects with simple URLs" do
    @request = Merb::Request.new({})
    result = @request.redirect("/")
    result.status.should == 302
    result.headers["Location"].should == "/"
  end

  it "permanently redirects" do
    @request = Merb::Request.new({})
    result = @request.redirect("/", :permanent => true)
    result.status.should == 301
    result.headers["Location"].should == "/"
  end

  it "redirects with messages" do
    @request = Merb::Request.new({})
    result = @request.redirect("/", :message => { :notice => "what?" })
    result.status.should == 302
    expected_url = Merb::Request.escape([Marshal.dump(:notice => "what?")].pack("m"))
    result.headers["Location"].should == "/?_message=#{expected_url}"
  end
end