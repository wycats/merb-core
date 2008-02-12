require File.join(File.dirname(__FILE__), "spec_helper")
require File.join(File.dirname(__FILE__), "controllers", "url")

class Monkey ; def to_param ; 45 ; end ; end


describe Merb::Controller, " url" do
  
  before do
    Merb::Router.prepare do |r|
      r.default_routes
      r.resources :monkeys
      r.match(%r{/foo/(\d+)/}).to(:controller => 'asdf').name(:regexp)
      r.match('/people/:name').
        to(:controller => 'people', :action => 'show').name(:person)
      r.match('/argstrs').to(:controller => "args").name(:args)
    end
    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::Url, :index)
  end
  
  it "should match the :controller to the default route" do
    @controller.url(:controller => "monkeys").should eql("/monkeys")
  end

  it "should match the :controller,:action to the default route" do
    @controller.url(:controller => "monkeys", :action => "list").
      should eql("/monkeys/list")
  end
  
  it "should match the :controller,:action,:id to the default route" do
    @controller.url(:controller => "monkeys", :action => "list", :id => 4).
      should eql("/monkeys/list/4")
  end
  
  it "should match the :controller,:action,:id,:format to the default route" do
    @controller.url(:controller => "monkeys", :action => "list", :id => 4, :format => "xml").
      should eql("/monkeys/list/4.xml")
  end

  it "should raise an error" do
    lambda { @controller.url(:regexp) }.should raise_error
  end

  it "should match with a route param" do
    @controller.url(:person, :name => "david").should eql("/people/david")
  end

  it "should match without a route param" do
    @controller.url(:person).should eql("/people/")
  end

  it "should match with an additional param" do
    @controller.url(:person, :name => 'david', :color => 'blue').should eql("/people/david?color=blue")
  end
  
  it "should match with additional params" do
    url = @controller.url(:person, :name => 'david', :smell => 'funky', :color => 'blue')
    url.should match(%r{/people/david?.*color=blue})
    url.should match(%r{/people/david?.*smell=funky})
  end

  it "should match with extra params and an array" do
    @controller.url(:args, :monkey => [1,2]).should == "/argstrs?monkey[]=1&monkey[]=2"
  end
  
  it "should match with no second arg" do
    @controller.url(:monkeys).should == "/monkeys"
  end
  
  it "should match with an object as second arg" do
    @monkey = Monkey.new
    @controller.url(:monkey,@monkey).should == "/monkeys/45"
  end

  it "should match the delete route" do
    @monkey = Monkey.new
    @controller.url(:delete_monkey,@monkey).should == "/monkeys/45/delete"
  end
end