require File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper")

describe Spec::Example::ExampleGroupFactory do
  it "should return a MerbExampleGroup when given :spec_path => '/blah/spec/foo/' (anything other than controllers, views and helpers)" do
    example_group = Spec::Example::ExampleGroupFactory.create_example_group(
      "name", :spec_path => '/blah/spec/foo/blah.rb'
    ) {}
    example_group.superclass.should == Merb::Test::Rspec::Example::MerbExampleGroup
  end
end