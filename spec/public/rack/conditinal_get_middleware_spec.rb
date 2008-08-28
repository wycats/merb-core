require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "shared_example_groups")

require "sha1"

NOW = Time.now

class EtagController < Merb::Controller
  def non_matching_etag
    response = "Ruby world needs a Paste port. Or... CherryPy?"
    headers['ETag'] = Digest::SHA1.hexdigest(response)

    response
  end

  def matching_etag
    response = "Everybody loves Rack"
    headers['ETag'] = Digest::SHA1.hexdigest(response)

    response
  end  

  def no_etag
    # sanity check
    headers.delete('ETag')
    
    "Everyone loves Rack"
  end
end

class LastModifiedController < Merb::Controller
  def non_matching_last_modified
    response = "Who cares about efficiency? Just throw more hardware at the problem."
    headers[Merb::Const::LAST_MODIFIED] = :non_matching

    response
  end

  def matching_last_modified
    response = "Who cares about efficiency? Just throw more hardware at the problem."
    headers[Merb::Const::LAST_MODIFIED] = :matching

    response
  end

  def no_last_modified
    # sanity check
    headers.delete('Last-Modified')
    
    "Everyone loves Rack"
  end
end


Merb::Router.prepare do |r|
  r.match("/etag/match").to(:controller => "etag_controller", :action => "matching_etag")
  r.match("/etag/nomatch").to(:controller => "etag_controller", :action => "non_matching_etag")
  r.match("/etag/stomach").to(:controller => "etag_controller", :action => "no_etag")

  r.match("/last_modified/match").to(:controller => "last_modified_controller", :action => "matching_last_modified")
  r.match("/last_modified/nomatch").to(:controller => "last_modified_controller", :action => "non_matching_last_modified")
  r.match("/last_modified/stomach").to(:controller => "last_modified_controller", :action => "no_last_modified")
end



describe Merb::Rack::ConditionalGet do

  before(:each) do
    @app        = Merb::Rack::Application.new
    @middleware = Merb::Rack::ConditionalGet.new(@app)
  end
  
  describe "when response has no ETag header" do
    before(:each) do
      env = Rack::MockRequest.env_for('/etag/stomach')
      @status, @headers, @body = @middleware.call(env)        
    end

    it 'does not modify status' do
      @status.should == 200
    end

    it 'does not modify message-body' do
      @body.should == "Everyone loves Rack"
    end
  end

  describe "when response has ETag header" do
    describe "and it == to HTTP_IF_NONE_MATCH of the request" do
      before(:each) do
        env = Rack::MockRequest.env_for('/etag/match')
        env['HTTP_IF_NONE_MATCH'] =
          Digest::SHA1.hexdigest("Everybody loves Rack")
        @status, @headers, @body = @middleware.call(env)        
      end

      it 'sets status to "304"' do
        @status.should == 304
      end
      
      it 'returns no message-body' do
        @body.should == ""
      end
    end

    describe "and it IS NOT == to HTTP_IF_NONE_MATCH of the request" do
      before(:each) do
        env = Rack::MockRequest.env_for('/etag/nomatch')
        env['HTTP_IF_NONE_MATCH'] =
          Digest::SHA1.hexdigest("Everybody loves Rack")
        @status, @headers, @body = @middleware.call(env)
      end
      
      it 'does not modify status' do
        @status.should == 200
      end

      it 'does not modify message-body' do
        @body.should == "Ruby world needs a Paste port. Or... CherryPy?"
      end
    end
  end

  describe "when response has no Last-Modified header" do
    before(:each) do
      env = Rack::MockRequest.env_for('/last_modified/stomach')
      @status, @headers, @body = @middleware.call(env)
    end

    it 'does not modify status' do
      @status.should == 200
    end

    it 'does not modify message-body' do
      @body.should == "Everyone loves Rack"
    end
  end

  describe "when response has Last-Modified header" do
    describe "when response has Last-Modified header" do
      describe "and it == to HTTP_IF_NOT_MODIFIED_SINCE of the request" do
        before(:each) do
          env = Rack::MockRequest.env_for('/last_modified/match')
          env[Merb::Const::HTTP_IF_MODIFIED_SINCE] = :matching
          @status, @headers, @body = @middleware.call(env)
        end
        
        it 'sets status to "304"' do
          @status.should == 304
        end
        
        it 'returns no message-body' do
          @body.should == ""
        end
      end

      describe "and it IS NOT == to HTTP_IF_NOT_MODIFIED_SINCE of the request" do
        before(:each) do
          env = Rack::MockRequest.env_for('/last_modified/nomatch')
          env[Merb::Const::HTTP_IF_MODIFIED_SINCE] = :matching
          @status, @headers, @body = @middleware.call(env)
        end

        it 'does not modify status' do
          @status.should == 200
        end

        it 'does not modify message-body' do
          @body.should == "Who cares about efficiency? Just throw more hardware at the problem."
        end
      end
    end
  end
end
