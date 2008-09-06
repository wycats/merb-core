require File.join(File.dirname(__FILE__), "spec_helper")
Controllers = Merb::Test::Fixtures::Controllers

describe Merb::Controller, "#etag=" do
  
  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")    
    Merb::Router.prepare do |r|
      r.default_routes
    end
  end

  it 'sets ETag header' do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConditionalGet, :sets_etag)
    controller.headers['ETag'].should == '"39791e6fb09"'
  end
end



describe Merb::Controller, "#last_modified=" do
  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")    
    Merb::Router.prepare do |r|
      r.default_routes
    end
  end

  it 'sets Last-Modified header' do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConditionalGet, :sets_last_modified)
    controller.headers['Last-Modified'].should == Time.at(7000).httpdate
  end
end


describe Merb::Controller, "#etag_matches?" do
  it 'returns true when response ETag header equals to request If-None-Match header' do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConditionalGet, :sets_etag, {}, { Merb::Const::HTTP_IF_NONE_MATCH => '"39791e6fb09"' } )
    controller.etag_matches?('"39791e6fb09"').should be(true)
  end

  it 'returns false when response ETag header DOES NOT equal to request If-None-Match header' do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConditionalGet, :sets_etag, {}, { Merb::Const::HTTP_IF_NONE_MATCH => '"6fb91e09793"' } )
    controller.etag_matches?('"55789a6fb09"').should be(false)
  end
end



describe Merb::Controller, "#modified_since?" do
  before(:each) do
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConditionalGet,
                              :sets_last_modified, {}, { Merb::Const::HTTP_IF_MODIFIED_SINCE => Time.at(7000).httpdate })
  end
  
  it 'return true when response Last-Modified header value <= request If-Modified-Since header' do
    @controller.not_modified?(Time.at(5000)).should be(true)
    @controller.not_modified?(Time.at(6999)).should be(true)
  end

  it 'return false when response Last-Modified header value > request If-Modified-Since header' do
    @controller.not_modified?(Time.at(7003)).should be(false)
    @controller.not_modified?(Time.at(16999)).should be(false)
  end
end


describe Merb::Controller, "#request_fresh?" do
  it 'return true when ETag matches' do
    env = { 'HTTP_IF_MODIFIED_SINCE' => Time.at(8000).httpdate, Merb::Const::HTTP_IF_NONE_MATCH => '"39791e6fb09"' }
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConditionalGet,
                              :sets_etag, {}, env)

    @controller.request_fresh?.should be(true)
  end

  it 'return true when entity is not modified since date given in request header' do
    env = { Merb::Const::HTTP_IF_MODIFIED_SINCE => Time.at(7000).httpdate }
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConditionalGet,
                              :sets_last_modified, {}, env)
    
    @controller.request_fresh?.should be(true)
  end

  it 'return true when both etag and last modification date satisfy request freshness' do
    env = { 'HTTP_IF_MODIFIED_SINCE' => Time.at(7000).httpdate, Merb::Const::HTTP_IF_NONE_MATCH => '"39791e6fb09"' }    
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConditionalGet,
                              :superfresh, {}, env)
    
    @controller.request_fresh?.should be(true)
  end

  it 'return false when neither etag nor last modification date satisfy request freshness' do
    env = { 'HTTP_IF_MODIFIED_SINCE' => Time.at(7000).httpdate, Merb::Const::HTTP_IF_NONE_MATCH => '"39791e6fb09"' }    
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConditionalGet,
                              :stale, {}, env)
    
    @controller.request_fresh?.should be(false)
  end  
end
