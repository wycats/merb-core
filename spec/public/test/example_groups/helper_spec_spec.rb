require File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper")

describe Spec::Example::ExampleGroupFactory do
  it "should return a HelperExampleGroup when given :type => :helper" do
    example_group = Spec::Example::ExampleGroupFactory.create_example_group(
      "name", :type => :helper
    ) {}
    example_group.superclass.should == Merb::Test::Rspec::Example::HelperExampleGroup
  end

  it "should return a HelperExampleGroup when given :spec_path => '/blah/spec/helpers/'" do
    example_group = Spec::Example::ExampleGroupFactory.create_example_group(
      "name", :spec_path => '/blah/spec/helpers/blah.rb'
    ) {}
    example_group.superclass.should == Merb::Test::Rspec::Example::HelperExampleGroup
  end
end