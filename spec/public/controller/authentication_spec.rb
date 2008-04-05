require File.join(File.dirname(__FILE__), "spec_helper")

describe "basic_authentication in general", :shared => true do
  
  it "should halt the filter chain and return a 401 status code if no authentication is sent" do
    response = dispatch_to(Merb::Test::Fixtures::Controllers::BasicAuthentication, :index)
    response.body.should == "HTTP Basic: Access denied.\n"
    response.status.should == 401
  end
  
  it "should halt the filter chain and return a 401 status code on invalid username and password" do
    u, p = "John", "password"
    response = dispatch_with_basic_authentication_to(Merb::Test::Fixtures::Controllers::BasicAuthentication, :index, u, p)
    response.body.should == "HTTP Basic: Access denied.\n"
    response.status.should == 401
  end
  
  it "should halt the filter chain and return a 401 status code on invalid username and valid password" do
    u, p = "John", "secret"
    response = dispatch_with_basic_authentication_to(Merb::Test::Fixtures::Controllers::BasicAuthentication, :index, u, p)
    response.body.should == "HTTP Basic: Access denied.\n"
    response.status.should == 401
  end
  
  it "should halt the filter chain and return a 401 status code on valid username and invalid password" do
    u, p = "Fred", "password"
    response = dispatch_with_basic_authentication_to(Merb::Test::Fixtures::Controllers::BasicAuthentication, :index, u, p)
    response.body.should == "HTTP Basic: Access denied.\n"
    response.status.should == 401
  end
  
  it "should call the action on invalid username and password" do
    u, p = "Fred", "secret"
    response = dispatch_with_basic_authentication_to(Merb::Test::Fixtures::Controllers::BasicAuthentication, :index, u, p)
    response.body.should == "authenticated"
    response.status.should == 200
  end
  
end

describe Merb::Controller, "#basic_authentication with no realm" do

  it_should_behave_like "basic_authentication in general"

  it "should have a default WWW-Authenticate realm of 'Application' if no authentication is sent" do
    response = dispatch_to(Merb::Test::Fixtures::Controllers::BasicAuthentication, :index)
    response.headers['WWW-Authenticate'] = 'Basic realm="Application"'
  end
  
  it "should have a default WWW-Authenticate realm of 'Application' if incorrect authentication is sent" do
    u, p = "John", "password"
    response = dispatch_with_basic_authentication_to(Merb::Test::Fixtures::Controllers::BasicAuthentication, :index, u, p)
    response.headers['WWW-Authenticate'] = 'Basic realm="Application"'
  end

end

describe Merb::Controller, "#basic_authentication with realm" do
  
  it_should_behave_like "basic_authentication in general"
  
  it "should set the WWW-Authenticate realm if no authentication is sent" do
    response = dispatch_to(Merb::Test::Fixtures::Controllers::BasicAuthenticationWithRealm, :index)
    response.headers['WWW-Authenticate'] = 'Basic realm="My SuperApp"'
  end
  
  it "should set the WWW-Authenticate realm if incorrect authentication is sent" do
    u, p = "John", "password"
    response = dispatch_with_basic_authentication_to(Merb::Test::Fixtures::Controllers::BasicAuthenticationWithRealm, :index, u, p)
    response.headers['WWW-Authenticate'] = 'Basic realm="My SuperApp"'
  end
  
end

describe Merb::Controller, "#basic_authentication.authenticate" do
  
  it "should be false on invalid username and password" do
    u, p = "John", "password"
    response = dispatch_with_basic_authentication_to(Merb::Test::Fixtures::Controllers::AuthenticateBasicAuthentication, :index, u, p)
    response.body.should == "denied"
  end
  
  it "should be false on invalid username and valid password" do
    u, p = "John", "secret"
    response = dispatch_with_basic_authentication_to(Merb::Test::Fixtures::Controllers::AuthenticateBasicAuthentication, :index, u, p)
    response.body.should == "denied"
  end
  
  it "should be false on valid username and invalid password" do
    u, p = "Fred", "password"
    response = dispatch_with_basic_authentication_to(Merb::Test::Fixtures::Controllers::AuthenticateBasicAuthentication, :index, u, p)
    response.body.should == "denied"
  end
  
  it "should be true on valid username and password" do
    u, p = "Fred", "secret"
    response = dispatch_with_basic_authentication_to(Merb::Test::Fixtures::Controllers::AuthenticateBasicAuthentication, :index, u, p)
    response.body.should == "authenticated"
  end

end

describe Merb::Controller, "#basic_authentication.request" do
  
  it "should halt the filter chain and return a 401 status code" do
    response = dispatch_to(Merb::Test::Fixtures::Controllers::RequestBasicAuthentication, :index)
    response.body.should == "HTTP Basic: Access denied.\n"
    response.status.should == 401
  end
  
  it "should have a default WWW-Authenticate realm of 'Application'" do
    response = dispatch_to(Merb::Test::Fixtures::Controllers::RequestBasicAuthentication, :index)
    response.headers['WWW-Authenticate'] = 'Basic realm="Application"'
  end
  
  it "should set the WWW-Authenticate realm" do
    response = dispatch_to(Merb::Test::Fixtures::Controllers::RequestBasicAuthenticationWithRealm, :index)
    response.headers['WWW-Authenticate'] = 'Basic realm="My SuperApp"'
  end

end