require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::Controller, "._default_cookie_domain" do
    
  before(:each) do
    Merb::Config[:default_cookie_domain].should_not be(nil)
  end
  
  it 'is set to Merb::Config[:default_cookie_domain] by default' do
    Merb::Controller._default_cookie_domain.should == Merb::Config[:default_cookie_domain]
    Merb::Test::Fixtures::Controllers::CookiesController._default_cookie_domain.should ==
      Merb::Config[:default_cookie_domain]
  end

  it "can be overridden for particular controller" do
    Merb::Test::Fixtures::Controllers::OverridingDefaultCookieDomain._default_cookie_domain.should ==
      "overridden.merbivore.com"
  end

  it 'is inherited by subclasses unless overriden' do
    Merb::Test::Fixtures::Controllers::NotOverridingDefaultCookieDomain._default_cookie_domain.should ==
      Merb::Config[:default_cookie_domain]
  end
end

describe Merb::Controller, "#cookies creating" do
  
  it "should set all the cookies for a request" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::CookiesController, :store_cookies)
    controller.headers['Set-Cookie'].length.should == 4
  end
  
  it "should set a simple cookie" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::CookiesController, :store_cookies)
    cookie = controller.headers['Set-Cookie'].sort[1]
    cookie.should match(/foo=bar;/)
    cookie.should match(/domain=specs.merbivore.com;/)
  end
  
  it "should set the cookie domain correctly when it is specified" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::CookiesController, :store_cookies)
    cookie = controller.headers['Set-Cookie'].sort[0]
    cookie.should match(/awesome=super-cookie;/)
    cookie.should match(/domain=blog.merbivore.com;/)
  end
  
  it "should format the expires time to the correct format" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::CookiesController, :store_cookies)
    cookie = controller.headers['Set-Cookie'].sort[2]
    cookie.should include("oldcookie=this+is+really+old;")
    cookie.should include("expires=Wed, 01-Jan-2020 00:00:00 GMT;")
  end
  
  it "should append secure to the end of the cookie header when marked as such" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::CookiesController, :store_cookies)
    cookie = controller.headers['Set-Cookie'].sort[3]
    cookie.should match(/secure$/)
  end
  
  it "sets the Set-Cookie response header - and ignores blank options" do
    controller_klass = Merb::Test::Fixtures::Controllers::EmptyDefaultCookieDomain
    with_cookies(controller_klass) do |cookie_jar|
      controller = dispatch_to(controller_klass, :store_cookies)
      cookies = controller.headers['Set-Cookie'].sort
      cookies[1].should == "foo=bar; path=/;"
    end
  end
    
  it "it gives access to cookie values" do
    controller_klass = Merb::Test::Fixtures::Controllers::CookiesController
    with_cookies(controller_klass) do |cookie_jar|
      controller = dispatch_to(controller_klass, :store_cookies)
      controller = dispatch_to(controller_klass, :retrieve_cookies)
      controller.cookies['awesome'].should == 'super-cookie'
      controller.cookies['foo'].should == 'bar'
      controller.cookies.should == cookie_jar
    end
  end
  
end

describe Merb::Controller, "#cookies destroying" do
  
  it "should send a cookie when deleting a cookie" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::CookiesController, :destroy_cookies)
    controller.headers['Set-Cookie'].length.should == 1
  end
  
  it "should set the expiration time of the cookie being destroyed to the past" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::CookiesController, :destroy_cookies)
    cookie = controller.headers['Set-Cookie'].sort[0]
    cookie.should include("expires=Thu, 01-Jan-1970 00:00:00 GMT;")
  end
  
end
