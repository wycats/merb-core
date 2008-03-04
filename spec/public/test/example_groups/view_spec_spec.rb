require File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper")

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

describe "A view spec", :type => :view do
  it "should include Merb::Test::Rspec::ViewMatchers" do
    self.class.superclass.should include(Merb::Test::Rspec::ViewMatchers)
  end
end
