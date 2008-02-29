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
end