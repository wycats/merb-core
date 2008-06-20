require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require "mongrel"

describe Merb::Request do
  it "should handle file upload for multipart/form-data posts" do
    file = Struct.new(:read, :filename, :path).
      new("This is a text file with some small content in it.", "sample.txt", "sample.txt")
    m = Merb::Test::MultipartRequestHelper::Post.new :file => file
    body, head = m.to_multipart
    request = fake_request({:request_method => "POST", :content_type => head, :content_length => body.length}, :req => body)
    request.params[:file].should_not be_nil
    request.params[:file][:tempfile].class.should == Tempfile
    request.params[:file][:content_type].should == 'text/plain'
  end
  
  it "should accept env['rack.input'] as IO object (instead of StringIO)" do
    file = Struct.new(:read, :filename, :path).
      new("This is a text file with some small content in it.", "sample.txt", "sample.txt")
    m = Merb::Test::MultipartRequestHelper::Post.new :file => file
    body, head = m.to_multipart
    
    t = Tempfile.new("io")
    t.write(body)
    t.close
    
    fd = IO.sysopen(t.path)
    io = IO.for_fd(fd,"r")
    request = Merb::Test::RequestHelper::FakeRequest.new({:request_method => "POST", :content_type => 'multipart/form-data, boundary=----------0xKhTmLbOuNdArY', :content_length => body.length},io)

    running {request.params}.should_not raise_error        
    request.params[:file].should_not be_nil
    request.params[:file][:tempfile].class.should == Tempfile
    request.params[:file][:content_type].should == 'text/plain'
  end    
    
  it "should handle GET with a content_type but an empty body (happens in some browsers such as safari after redirect)" do
      request = fake_request({:request_method => "GET", :content_type => 'multipart/form-data, boundary=----------0xKhTmLbOuNdArY', :content_length => 0}, :req => '')      
      running {request.params}.should_not raise_error        
  end
  
end