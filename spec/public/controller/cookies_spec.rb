require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::Controller, "._session_cookie_domain" do
  before(:each) do
    Merb::Config[:session_cookie_domain].should_not be(nil)
  end
  
  it 'is set to Merb::Config[:session_cookie_domain] by default' do
    Merb::Controller._session_cookie_domain.should == Merb::Config[:session_cookie_domain]
    Merb::Test::Fixtures::Controllers::CookiesController._session_cookie_domain.should ==
      Merb::Config[:session_cookie_domain]
  end

  it "can be overridden for particular controller" do
    Merb::Test::Fixtures::Controllers::OverridingSessionCookieDomain._session_cookie_domain.should ==
      "overridden.merbivore.com"
  end

  it 'is inherited by subclasses unless overriden' do
    Merb::Test::Fixtures::Controllers::NotOverridingSessionCookieDomain._session_cookie_domain.should ==
      Merb::Config[:session_cookie_domain]
  end
end
