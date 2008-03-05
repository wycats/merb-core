require File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper")

Merb.start :environment => 'test', :log_level => :fatal

describe Spec::Example::ExampleGroupFactory do
  it "should return a ViewExampleGroup when given :type => :model" do
    example_group = Spec::Example::ExampleGroupFactory.create_example_group(
      "name", :type => :view
    ) {}
    example_group.superclass.should == Merb::Test::Rspec::Example::ViewExampleGroup
  end

  it "should return a ViewExampleGroup when given :spec_path => '/blah/spec/views/'" do
    example_group = Spec::Example::ExampleGroupFactory.create_example_group(
      "name", :spec_path => '/blah/spec/views/blah.rb'
    ) {}
    example_group.superclass.should == Merb::Test::Rspec::Example::ViewExampleGroup
  end
end

class Merb::Controller
  self._template_root = File.join(File.dirname(__FILE__), 'views')
end

module Merb::HelloWorldHelper
  def hello_world; "Hello World!"; end
end

module Merb::HelloUniverseHelper
  def hello_universe; "Hello Universe!"; end
end

describe "A view spec", :type => :view do
  it "should include Merb::Test::Rspec::ViewMatchers" do
    self.class.superclass.should include(Merb::Test::Rspec::ViewMatchers)
  end

  it "should render simple template" do
    render 'test/simple.html'
    body.should == "Hello World!"
  end

  it "should render template with helper" do
    render 'test/one_helper.html', :helper => Merb::HelloWorldHelper
    body.should == "Hello World!"
  end

  it "should render template with multiple helpers" do
    render 'test/multiple_helpers.html', :helpers => [Merb::HelloWorldHelper, Merb::HelloUniverseHelper]
    body.should == "Hello World!\nHello Universe!"
  end

  it "should render template with assigned variables" do
    assigns[:name] = "John"
    render 'test/assigns.html'
    body.should == "Hello John!"
  end
end
