require File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper")

describe Spec::Example::ExampleGroupFactory do
  it "should return a RoutingExampleGroup when given :type => :routing" do
    example_group = Spec::Example::ExampleGroupFactory.create_example_group(
      "name", :type => :route
    ) {}
    example_group.superclass.should == Merb::Test::Rspec::Example::RouteExampleGroup
  end

  it "should return a RoutingExampleGroup when given :spec_path => '/blah/spec/routes/'" do
    example_group = Spec::Example::ExampleGroupFactory.create_example_group(
      "name", :spec_path => '/blah/spec/routes/blah.rb'
    ) {}
    example_group.superclass.should == Merb::Test::Rspec::Example::RouteExampleGroup
  end
end

describe "A route spec", :type => :route do
  it "should include Merb::Test::Rspec::RouteMatchers" do
    self.class.superclass.should include(Merb::Test::Rspec::RouteMatchers)
  end
end