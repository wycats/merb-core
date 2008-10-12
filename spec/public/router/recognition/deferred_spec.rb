require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Recognizing requests for deferred routes" do

  describe "that route the request to a controller" do
    before :each do
      Merb::Router.prepare do      
        match("/deferred/:zoo").defer_to do |request, params|
          params.merge(:controller => "w00t") if params[:zoo]
        end
      end    
    end

    it "should match routes based on the incoming params" do
      route_for("/deferred/baz", :boo => "12").should have_route(:controller => "w00t", :zoo => "baz")
    end

    it "should not use the route if it does not match the defered block" do
      lambda { route_for("/deferred") }.should raise_not_found
    end

    it "should return the param hash returned by the block" do
      Merb::Router.prepare do
        match("/deferred").defer_to do |request, params|
          { :hello => "world" }
        end
      end

      route_for("/deferred").should have_route(:hello => "world")
    end

    it "should accept params" do
      Merb::Router.prepare do
        match("/").defer_to(:controller => "accounts") do |request, params|
          params.update(:action => "hello")
        end
      end

      route_for("/").should have_route(:controller => "accounts", :action => "hello")
    end

    it "should be able to define routes after the deferred route" do
      Merb::Router.prepare do
        match("/deferred").defer_to do
          { :hello => "world" }
        end

        match("/").to(:foo => "bar")
      end

      route_for("/deferred").should have_route(:hello => "world")
      route_for("/").should         have_route(:foo => "bar")
    end
  end
  
  describe "that redirect to request to another path" do
    
    it "should be able to redirect from inside the deferred block" do
      Merb::Router.prepare do
        match("/").defer_to do
          redirect "/hello"
        end
      end
      
      route_for("/").should have_rack(:status => 302, :headers => { "Location" => "/hello" })
    end
    
    it "should be able to set the redirect status" do
      Merb::Router.prepare do
        match("/").defer_to do
          redirect "/hello"
        end
      end
      
      route_for("/").should have_rack(:status => 302, :headers => { "Location" => "/hello" })
    end
    
    it "should be able to use #url in deferred blocks" do
      Merb::Router.prepare do
        match("/").defer_to { redirect url(:homepage) }
        match("/home").to(:controller => "home").name(:homepage)
      end
      
      route_for("/").should have_rack(:headers => { "Location" => "/home" })
    end
    
  end
  
end

describe "Recognizing requests for stacked deferred routes" do
  
  it "should route the request normally" do
    Merb::Router.prepare do
      first  = Proc.new { |req, p| p }
      second = Proc.new { |req, p| p }
      third  = Proc.new { |req, p| p }
      
      defer(first).defer(second).defer(third) do
        match("/hello").to(:controller => "greetings")
      end
    end
    
    route_for("/hello").should have_route(:controller => "greetings")
  end
  
  it "should run all the deferred procs in order" do
    Merb::Router.prepare do
      first  = Proc.new { |req, p| req.first_proc!  ; p }
      second = Proc.new { |req, p| req.second_proc! ; p }
      third  = Proc.new { |req, p| req.third_proc!  ; p }
      
      defer(first).defer(second).defer(third) do
        match("/hello").to(:controller => "greetings")
      end
    end
    
    route_for("/hello") do |req|
      req.should_receive(:first_proc!)
      req.should_receive(:second_proc!)
      req.should_receive(:third_proc!)
    end
  end
  
  it "should abort the deferred stack if one of the procs marks the request as matched" do
    Merb::Router.prepare do
      first  = Proc.new { |req, p| req.first_proc!  ; p }
      second = Proc.new { |req, p| req.second_proc! ; req.matched! ; p }
      third  = Proc.new { |req, p| req.third_proc!  ; p }
      
      defer(first).defer(second).defer(third) do
        match("/hello").to(:controller => "greetings")
      end
    end
    
    route_for("/hello") do |req|
      req.should_receive(:first_proc!)
      req.should_receive(:second_proc!)
      req.should_not_receive(:third_proc!)
    end
  end
  
  it "should abort the deferred stack if one of the procs redirects the request" do
    Merb::Router.prepare do
      first  = Proc.new { |req, p| req.first_proc!  ; p }
      second = Proc.new { |req, p| req.second_proc! ; redirect("/goodbye") }
      third  = Proc.new { |req, p| req.third_proc!  ; p }
      
      defer(first).defer(second).defer(third) do
        match("/hello").to(:controller => "greetings")
      end
    end
    
    route_for("/hello") do |req|
      req.should_receive(:first_proc!)
      req.should_receive(:second_proc!)
      req.should_not_receive(:third_proc!)
    end
  end
  
  it "should match the deferred route if none of the blocks return false / nil" do
    Merb::Router.prepare do
      first  = Proc.new { |req, p| p }
      second = Proc.new { |req, p| p }
      
      match("/hello").defer(first).defer(second).to(:controller => "deferred")
      match("/hello").to(:controller => "not_deferred")
    end
    
    route_for("/hello").should have_route(:controller => "deferred")
  end
  
  it "should not match the deferred route if any of the blocks return false / nil" do
    Merb::Router.prepare do
      first  = Proc.new { |req, p| nil }
      second = Proc.new { |req, p| p }
      
      match("/hello").defer(first).defer(second).to(:controller => "deferred")
      match("/hello").to(:controller => "not_deferred")
    end
    
    route_for("/hello").should have_route(:controller => "not_deferred")
    
    Merb::Router.prepare do
      first  = Proc.new { |req, p| p }
      second = Proc.new { |req, p| nil }
      
      match("/hello").defer(first).defer(second).to(:controller => "deferred")
      match("/hello").to(:controller => "not_deferred")
    end
    
    route_for("/hello").should have_route(:controller => "not_deferred")
  end
  
  it "should be able to use the same deferred block in multiple routes" do
    Merb::Router.prepare do
      block = Proc.new { |req, p| req.in_block! ; p }

      defer(block).with(:controller => "deferred") do
        match("/first").register
        match("/second").register
      end
    end
    
    route_for("/first")  { |req| req.should_receive(:in_block!) }
    route_for("/second") { |req| req.should_receive(:in_block!) }
  end
  
end
