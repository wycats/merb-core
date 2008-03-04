require File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper")

describe Spec::Example::ExampleGroupFactory do
  it "should return a ModelExampleGroup when given :type => :model" do
    example_group = Spec::Example::ExampleGroupFactory.create_example_group(
      "name", :type => :model
    ) {}
    example_group.superclass.should == Merb::Test::Rspec::Example::ModelExampleGroup
  end

  it "should return a ModelExampleGroup when given :spec_path => '/blah/spec/models/'" do
    example_group = Spec::Example::ExampleGroupFactory.create_example_group(
      "name", :spec_path => '/blah/spec/models/blah.rb'
    ) {}
    example_group.superclass.should == Merb::Test::Rspec::Example::ModelExampleGroup
  end
end