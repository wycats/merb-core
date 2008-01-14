require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::Request, " #method" do
  
  [:get, :head, :put, :delete].each do |method|
    it "should use the HTTP if it was a #{method.to_s.upcase}" do
      fake_request(:request_method => method.to_s).method.should == method
    end

    it "should use the _method for #{method.to_s.upcase} when it came in as a POST" do
      request = fake_request({:request_method => "POST"}, :post_body => "_method=#{method}")
      request.method.should == method
    end
    
    [:get, :head, :put, :delete].each do |meth|
      it "should return #{method == meth} when calling #{meth}? and the method is :#{method}" do
        request = fake_request({:request_method => method.to_s})
        request.send("#{meth}?").should == (method == meth)
      end
    end
  end

  it "should default to POST if the _method is not defined" do
    request = fake_request({:request_method => "POST"}, :post_body => "_method=zed")
    request.method.should == :post
  end
    
end

describe Merb::Request, " query and body params" do
  {"foo=bar&baz=bat"        => {"foo" => "bar", "baz" => "bat"},
   "foo[]=bar&foo[]=baz"    => {"foo" => ["bar", "baz"]},
   "foo[1]=bar&foo[2]=baz"  => {"foo" => {"1" => "bar", "2" => "baz"}}}.each do |query, parse|

     it "should convert #{query.inspect} to #{parse.inspect} in the query string" do
       request = fake_request({:query_string => query})
       request.stub!(:route_params).and_return({})       
       request.params.should == parse
     end

     it "should convert #{query.inspect} to #{parse.inspect} in the post body" do
       request = fake_request({}, :post_body => query)
       request.stub!(:route_params).and_return({})
       request.params.should == parse
     end
   
   end
end

describe Merb::Request, " cookies" do
  
  it "should take cookies in the HTTP_COOKIE environment variable" do
    request = fake_request({:http_cookie => "merb=canhascookie; version=1"})
    request.cookies.should == {"merb" => "canhascookie", "version" => "1"}
  end
  
end