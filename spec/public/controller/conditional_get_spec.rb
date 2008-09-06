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
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConditionalGet, :etag)
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

  it 'sets ETag header' do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConditionalGet, :last_modified)
    controller.headers['Last-Modified'].should == Time.at(7000).httpdate
  end
end


describe Merb::Controller, "#etag_matches?" do
  it 'return true when response ETag header equals to request If-None-Match header' do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::ConditionalGet, :etag, {}, { 'HTTP_IF_NONE_MATCH' => '"39791e6fb09"' } )
    puts controller.headers.inspect
    controller.etag_matches?('"39791e6fb09"').should be(true)
  end
end
