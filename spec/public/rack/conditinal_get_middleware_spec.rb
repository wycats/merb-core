require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

require "sha1"

class ConditionalGetTestController < Merb::Controller
  def with_etag
    response = "original message-body"
    headers['ETag'] = Digest::SHA1.hexdigest(response)

    response
  end

  def with_last_modified
    headers[Merb::Const::LAST_MODIFIED] = :documents_last_modified_time
    "original message-body"
  end

  def without
    # sanity check
    headers.delete('ETag')
    headers.delete(Merb::Const::LAST_MODIFIED)
    
    "original message-body"
  end
end


Merb::Router.prepare do |r|
  r.match("/with_etag").to(
    :controller => "conditional_get_test_controller", :action => "with_etag"
  )
  r.match("/with_last_modified").to(
    :controller => "conditional_get_test_controller", :action => "with_last_modified"
  )
  r.match("/without").to(
    :controller => "conditional_get_test_controller", :action => "without"
  )
end

describe Merb::Rack::ConditionalGet do

  describe(
    "when the client already has an up-to-date document", 
    :shared => true
  ) do
    it 'sets status to "304"' do
      @status.should == 304
    end

    it 'returns no message-body' do
      @body.should == ""
    end
  end

  describe(
    "when the client does NOT have an up-to-date document",
    :shared => true
  ) do
    it 'does not modify status' do
      @status.should == 200
    end

    it 'does not modify message-body' do
      @body.should == "original message-body"
    end
  end
  
  before(:each) do
    @app        = Merb::Rack::Application.new
    @middleware = Merb::Rack::ConditionalGet.new(@app)
  end
  
  describe "when response has no ETag header and no Last-Modified header" do
    before(:each) do
      env = Rack::MockRequest.env_for('/without')
      @status, @headers, @body = @middleware.call(env)        
    end
    
    it_should_behave_like "when the client does NOT have an up-to-date document"
  end

  describe "when response has ETag header" do
    describe "and it == to HTTP_IF_NONE_MATCH of the request" do
      before(:each) do
        env = Rack::MockRequest.env_for('/with_etag')
        env['HTTP_IF_NONE_MATCH'] =
          Digest::SHA1.hexdigest("original message-body")
        @status, @headers, @body = @middleware.call(env)        
      end

      it_should_behave_like "when the client already has an up-to-date document"
    end

    describe "and it IS NOT == to HTTP_IF_NONE_MATCH of the request" do
      before(:each) do
        env = Rack::MockRequest.env_for('/with_etag')
        env['HTTP_IF_NONE_MATCH'] =
          Digest::SHA1.hexdigest("a different message-body")
        @status, @headers, @body = @middleware.call(env)
      end
      
      it_should_behave_like "when the client does NOT have an up-to-date document"
    end
  end

  describe "when response has Last-Modified header" do
    describe "and it == to HTTP_IF_NOT_MODIFIED_SINCE of the request" do
      before(:each) do
        env = Rack::MockRequest.env_for('/with_last_modified')
        env[Merb::Const::HTTP_IF_MODIFIED_SINCE] = :documents_last_modified_time
        @status, @headers, @body = @middleware.call(env)
      end
      
      it_should_behave_like "when the client already has an up-to-date document"
    end

    describe "and it IS NOT == to HTTP_IF_NOT_MODIFIED_SINCE of the request" do
      before(:each) do
        env = Rack::MockRequest.env_for('/with_last_modified')
        env[Merb::Const::HTTP_IF_MODIFIED_SINCE] = :some_other_time
        @status, @headers, @body = @middleware.call(env)
      end

      it_should_behave_like "when the client does NOT have an up-to-date document"
    end
  end
end
