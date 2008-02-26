require File.join(File.dirname(__FILE__), "spec_helper")
Merb.start :environment => 'test'
module CookiesSpecModule
  
  def cookie_time(time)
    time.gmtime.strftime(Merb::Const::COOKIE_EXPIRATION_FORMAT)
  end
end

describe Merb::Cookies do
  include CookiesSpecModule

  before do
    @_cookies = Mash.new
    @_headers = {}
    @cookies = Merb::Cookies.new(@_cookies, @_headers)
  end

  it "should respond to []" do
    @cookies.should respond_to(:[])
  end

  it "should respond to []=" do
    @cookies.should respond_to(:[]=)
  end

  it "should respond to delete" do
    @cookies.should respond_to(:delete)
  end

  it "should accept simple cookies that expire at end of session" do
    @cookies[:foo] = 'bar'

    @_headers['Set-Cookie'].should == ['foo=bar; path=/;']

    @cookies[:foo].should == 'bar'
    @cookies['foo'].should == 'bar'
  end

  it "should accept cookies with expiry dates" do
    expires = Time.now + 2 * (60*60*24*7)
    @cookies[:dozen] = {
      :value => 'twelve',
      :expires => expires
    }

    @_headers['Set-Cookie'].should ==
      ["dozen=twelve; expires=%s; path=/;" % cookie_time(expires)]

    @cookies[:dozen].should == 'twelve'
    @cookies['dozen'].should == 'twelve'
  end

  it "should accept multiple cookies" do
    expires = Time.now + 2 * (60*60*24*7)
    @cookies[:foo] = 'bar'
    @cookies[:dozen] = {
      :value => 'twelve',
      :expires => expires
    }

    @_headers['Set-Cookie'].should == [
      'foo=bar; path=/;',
      "dozen=twelve; expires=%s; path=/;" % cookie_time(expires)
    ]

    @cookies[:dozen].should == 'twelve'
    @cookies['dozen'].should == 'twelve'
    @cookies[:foo].should == 'bar'
    @cookies['foo'].should == 'bar'
  end

  it "should leave the value unescaped in the current request" do
    @cookies[:foo] = "100%"
    @_headers['Set-Cookie'].should == [
      'foo=100%25; path=/;'
    ]

    @cookies[:foo].should == '100%'
    @cookies['foo'].should == '100%'
  end

  it "should give access to currently saved cookies" do
    @_cookies[:original] = 'accessible'
    @cookies[:original].should == 'accessible'

    @cookies[:foo] = 'bar'
    @cookies[:foo].should == 'bar'
    @cookies[:original].should == 'accessible'
  end

  it "should overwrite old cookies with new cookies" do
    @_cookies[:foo] = 'bar'
    @cookies[:foo].should == 'bar'

    @cookies[:foo] = 'new'
    @cookies[:foo].should == 'new'
  end

  it "should allow deleting of cookies" do
    @_cookies[:foo] = 'bar'
    @cookies[:foo].should == 'bar'

    @cookies.delete(:foo)
    @cookies[:foo].should == nil
  end
end