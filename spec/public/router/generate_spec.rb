require File.join(File.dirname(__FILE__), "spec_helper")

describe "The URL generator with default routes" do
  before(:each) do
    Merb::Router.prepare {|r| r.default_routes}
  end

  it "should match the :controller to the default route" do
    generate(:controller => "monkeys").should eql("/monkeys")
  end

  it "should match the :controller,:action to the default route" do
    generate(:controller => "monkeys", :action => "list").
      should eql("/monkeys/list")
  end

  it "should match the :controller,:action,:id to the default route" do
    generate(:controller => "monkeys", :action => "list", :id => 4).
      should eql("/monkeys/list/4")
  end

  it "should match the :controller,:action,:id,:format to the default route" do
    generate(:controller => "monkeys", :action => "list", :id => 4, :format => "xml").
      should eql("/monkeys/list/4.xml")
  end
end

describe "The URL generator with a regex route" do
  before(:each) do
    Merb::Router.prepare {|r|
      r.match(%r{/foo/(\d+)/}).to(:controller => 'asdf').name(:regexp)
    }
  end
  
  it "should raise an error" do
    lambda { generate(:regexp) }.should raise_error
  end
end

describe "The URL generator with a named route" do
  before(:each) do
    Merb::Router.prepare {|r|
      r.match('/people/:name').
        to(:controller => 'people', :action => 'show').name(:person)
      r.match('/argstrs').to(:controller => "args").name(:args)
    }
  end
  
  it "should match with a route param" do
    generate(:person, :name => "david").should eql("/people/david")
  end

  it "should match without a route param" do
    generate(:person).should eql("/people/")
  end
  
  it "should match with an additional param" do
    generate(:person, :name => 'david', :color => 'blue').should eql("/people/david?color=blue")
  end

  it "should match with additional params" do
    url = generate(:person, :name => 'david', :smell => 'funky', :color => 'blue')
    url.should match(%r{/people/david?.*color=blue})
    url.should match(%r{/people/david?.*smell=funky})
  end
  
  it "should match with extra params and an array" do
    generate(:args, :monkey => [1,2]).should == "/argstrs?monkey[]=1&monkey[]=2"
  end
end