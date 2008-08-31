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

  it "should call the action on valid username and password" do
    u, p = "Fred", "secret"
    response = dispatch_with_basic_authentication_to(Merb::Test::Fixtures::Controllers::BasicAuthentication, :index, u, p)
    response.body.should == "authenticated"
    response.status.should == 200
  end

end

describe Merb::Controller do
  MTFC = Merb::Test::Fixtures::Controllers
  
  describe "#basic_authentication with no realm" do
    it_should_behave_like "basic_authentication in general"

    it "should have a default WWW-Authenticate realm of 'Application' if no authentication is sent" do
      response = dispatch_to(MTFC::BasicAuthentication, :index)
      response.headers['WWW-Authenticate'] = 'Basic realm="Application"'
    end

    it "should have a default WWW-Authenticate realm of 'Application' if incorrect authentication is sent" do
      u, p = "John", "password"
      response = dispatch_with_basic_authentication_to(MTFC::BasicAuthentication, :index, u, p)
      response.headers['WWW-Authenticate'] = 'Basic realm="Application"'
    end
  end

  describe "#basic_authentication with realm" do

    it_should_behave_like "basic_authentication in general"

    it "should set the WWW-Authenticate realm if no authentication is sent" do
      response = dispatch_to(MTFC::BasicAuthenticationWithRealm, :index)
      response.headers['WWW-Authenticate'] = 'Basic realm="My SuperApp"'
    end

    it "should set the WWW-Authenticate realm if incorrect authentication is sent" do
      u, p = "John", "password"
      response = dispatch_with_basic_authentication_to(MTFC::BasicAuthenticationWithRealm, :index, u, p)
      response.headers['WWW-Authenticate'] = 'Basic realm="My SuperApp"'
    end

  end

  describe  "#basic_authentication.authenticate" do

    it "should pass in the username and password and return the result of the block" do
      u, p = "Fred", "secret"
      response = dispatch_with_basic_authentication_to(MTFC::AuthenticateBasicAuthentication, :index, u, p)
      response.body.should == "Fred:secret"
    end

  end
  
  describe "#basic_authentication.request" do

    it "should halt the filter chain and return a 401 status code" do
      response = dispatch_to(MTFC::RequestBasicAuthentication, :index)
      response.body.should == "HTTP Basic: Access denied.\n"
      response.status.should == 401
    end

    it "should have a default WWW-Authenticate realm of 'Application'" do
      response = dispatch_to(MTFC::RequestBasicAuthentication, :index)
      response.headers['WWW-Authenticate'].should == 'Basic realm="Application"'
    end

    it "should set the WWW-Authenticate realm" do
      response = dispatch_to(MTFC::RequestBasicAuthenticationWithRealm, :index)
      response.headers['WWW-Authenticate'].should == 'Basic realm="My SuperApp"'
    end

  end

  describe "#basic_authentication.request!" do
    
    it "should not halt the filter chain and provide a 401 status code" do
      response = dispatch_to(MTFC::PassiveBasicAuthentication, :index)
      response.status = 401
    end
    
    it "should have a default WWW=Authentication realm of 'Application'" do
      response = dispatch_to(MTFC::PassiveBasicAuthentication, :index)
      response.headers['WWW-Authenticate'].should == 'Basic realm="Application"'
    end
    
    it "should set the WWW-Authenticate realm" do
      response = dispatch_to(MTFC::PassiveBasicAuthenticationWithRealm, :index)
      response.headers['WWW-Authenticate'].should == 'Basic realm="My Super App"'
    end
    
    it "should allow the action to render it's output" do
      response = dispatch_to(MTFC::PassiveBasicAuthentication, :index)
      response.body.should == "My Output"
    end

    it "should be callable from within an action" do
      response = dispatch_to(MTFC::PassiveBasicAuthenticationInAction, :index)
      response.body.should == "In Action"
      response.status.should == 401
    end

  end
  
  describe "basic_authentication.provided?" do
    
    it "should return true when basic authentication credentials have been supplied" do
      u, p = "Fred", "secret"
      response = dispatch_with_basic_authentication_to(MTFC::PassiveBasicAuthentication, :index, u, p)
      response.basic_authentication.provided?.should be_true
    end
    
    it "should return false when basic authentication credentials have not been supplied" do
      response = dispatch_to(MTFC::PassiveBasicAuthentication, :index)
      response.basic_authentication.provided?.should be_false
    end
  end
  
  describe "basic_authentication.username and password" do
    it "return username if set" do
      u, p = "Fred", "secret"
      response = dispatch_with_basic_authentication_to(MTFC::PassiveBasicAuthentication, :index, u, p)
      response.basic_authentication.username.should == "Fred"
    end
    
    it "should return nil if the username is not set" do
      response = dispatch_to(MTFC::PassiveBasicAuthentication, :index)
      response.basic_authentication.username.should be_nil
    end
    
    it "should return password if set" do
      u, p = "Fred", "secret"
      response = dispatch_with_basic_authentication_to(MTFC::PassiveBasicAuthentication, :index, u, p)
      response.basic_authentication.password.should == "secret"
    end
    
    it "shoudl return nil for the password if not set" do
      response = dispatch_to(MTFC::PassiveBasicAuthentication, :index)
      response.basic_authentication.password.should be_nil
    end
  end

end
