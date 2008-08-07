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


  describe "#set_cookie" do
    before :each do
      @expires         = Time.now + 2 * (60*60*24*7)
      @escaped_expires = cookie_time(@expires)
    end
    
    it "accepts simple cookies that expire at end of session" do
      @cookies[:foo] = 'bar'

      hdr = @_headers['Set-Cookie'].first
      hdr.should =~ /foo=bar;/
      hdr.should =~ / path=\/;/      
      @cookies[:foo].should == 'bar'
    end

    it "uses Mash, not Hash" do
      @cookies[:dozen] = {
        :value => 'twelve',
        :expires => @expires
      }

      @cookies[:dozen].should == 'twelve'
      @cookies['dozen'].should == 'twelve'
    end
    
    it "accepts cookies with expiry dates" do
      @cookies[:dozen] = {
        :value => 'twelve',
        :expires => @expires
      }

      hdr = @_headers['Set-Cookie'].first
      
      hdr.should =~ /dozen=twelve;/
      hdr.should =~ / expires=#{cookie_time(@expires)};/
    end

    
    it "accepts cookies with domain" do
      domain  = 'wiki.merbivore.com'
      
      @cookies[:dozen] = {
        :value => 'twelve',
        :expires => @expires,
        :domain  => domain
      }

      hdr = @_headers['Set-Cookie'].first
      
      hdr.should =~ /dozen=twelve;/
      hdr.should =~ / domain=#{domain};/      
    end

    
    it "uses / as default path" do
      Merb::Controller.should_receive(:_session_cookie_domain).and_return("session.cookie.domain")
      @cookies.set_cookie(:dozen, 'twelve', :expires => @expires)

      hdr = @_headers['Set-Cookie'].first
      hdr.should =~ / domain=session.cookie.domain;/
    end    

    
    it "uses / as default path" do
      @cookies[:dozen] = {
        :value   => 'twelve',
        :expires => @expires
      }

      hdr = @_headers['Set-Cookie'].first
      hdr.should =~ / path=\/;/
    end

    
    it "accepts cookies with path" do
      cookie_path = '/some/resource'
      
      @cookies[:dozen] = {
        :value   => 'twelve',
        :expires => @expires,
        :path    => cookie_path
      }

      hdr = @_headers['Set-Cookie'].first
      hdr.should =~ /dozen=twelve;/
      hdr.should =~ / path=#{cookie_path};/
    end


    it "accepts cookies with security flag" do
      @cookies[:dozen] = {
        :value   => 'twelve',
        :expires => @expires,
        :secure  => true
      }

      hdr = @_headers['Set-Cookie'].first
      hdr.should =~ /dozen=twelve;/
      hdr.should =~ / expires=#{cookie_time(@expires)};/
      hdr.should =~ / path=\/;/
      hdr.should =~ / secure$/
    end    

    it "accepts cookies with security flag set to false" do
      @cookies[:dozen] = {
        :value   => 'twelve',
        :expires => @expires,
        :secure  => false
      }

      hdr = @_headers['Set-Cookie'].first
      hdr.should =~ /dozen=twelve;/
      hdr.should =~ / expires=#{cookie_time(@expires)};/
      hdr.should =~ / path=\/;/
      hdr.should =~ /;$/
      hdr.should_not =~ /secure/
    end    
    

    it "accepts multiple cookies" do
      @cookies[:foo] = 'bar'
      @cookies[:dozen] = {
        :value   => 'twelve',
        :expires => @expires
      }

      first  = @_headers['Set-Cookie'].first
      second = @_headers['Set-Cookie'].last

      first.should =~ /foo=bar;/
      first.should =~ / path=\//
      second.should =~ /dozen=twelve;/
      second.should =~ / path=\//
      second.should =~ / expires=#{cookie_time(@expires)};/

      @cookies[:dozen].should == 'twelve'
      @cookies['dozen'].should == 'twelve'
      @cookies[:foo].should == 'bar'
      @cookies['foo'].should == 'bar'
    end

    it "leaves the value unescaped in the current request" do
      @cookies[:foo] = "100%"

      hdr = @_headers['Set-Cookie'].first
      hdr.should =~ /foo=100%25/
      
      @cookies[:foo].should == '100%'
      @cookies['foo'].should == '100%'
    end

    it "gives access to currently saved cookies" do
      @_cookies[:original] = 'accessible'
      @cookies[:original].should == 'accessible'

      @cookies[:foo] = 'bar'
      @cookies[:foo].should == 'bar'
      @cookies[:original].should == 'accessible'
    end

    it "overwrites old cookies with new cookies" do
      @_cookies[:foo] = 'bar'
      @cookies[:foo].should == 'bar'

      @cookies[:foo] = 'new'
      @cookies[:foo].should == 'new'
    end    
  end


  describe "#delete" do
    it "allows deleting of cookies" do
      @_cookies[:foo] = 'bar'
      @cookies[:foo].should == 'bar'

      @cookies.delete(:foo)
      @cookies[:foo].should == nil
    end

    it 'sets cookie expiration time in the past' do
      @_cookies[:foo] = 'bar'
      @cookies[:foo].should == 'bar'

      @cookies.delete(:foo)
      @_headers['Set-Cookie'].first.should =~ /#{cookie_time(Time.at(0))}/
    end
  end
end
