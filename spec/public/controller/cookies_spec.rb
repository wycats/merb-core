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
    Merb::Test::Fixtures::Controllers::OverridingSessionCookieDomain._default_cookie_domain.should ==
      "overridden.merbivore.com"
  end

  it 'is inherited by subclasses unless overriden' do
    Merb::Test::Fixtures::Controllers::NotOverridingSessionCookieDomain._default_cookie_domain.should ==
      Merb::Config[:default_cookie_domain]
  end
end

describe Merb::Controller, "#cookies" do
  
  it "sets the Set-Cookie response header" do
    controller_klass = Merb::Test::Fixtures::Controllers::CookiesController
    with_cookies(controller_klass) do |cookie_jar|
      controller = dispatch_to(controller_klass, :store_cookies)
      cookies = controller.headers['Set-Cookie'].sort
      cookies.length.should == 2
      cookies[0].should match(/awesome=super-cookie;/)
      cookies[0].should match(/domain=blog.merbivore.com;/)
      cookies[1].should match(/foo=bar;/)
      cookies[1].should match(/domain=specs.merbivore.com;/)
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
