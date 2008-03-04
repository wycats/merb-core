require File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper")

Merb.start :environment => 'test', :log_level => :fatal

describe Spec::Example::ExampleGroupFactory do
  it "should return a ControllerExampleGroup when given :type => :controller" do
    example_group = Spec::Example::ExampleGroupFactory.create_example_group(
      "name", :type => :controller
    ) {}
    example_group.superclass.should == Merb::Test::Rspec::Example::ControllerExampleGroup
  end

  it "should return a ControllerExampleGroup when given :spec_path => '/blah/spec/controllers/'" do
    example_group = Spec::Example::ExampleGroupFactory.create_example_group(
      "name", :spec_path => '/blah/spec/controllers/blah.rb'
    ) {}
    example_group.superclass.should == Merb::Test::Rspec::Example::ControllerExampleGroup
  end
end

class TestController < Merb::Controller
  def index; "the index action"; end
  def foobar; @foobar = 42; render; end
  def show; "showing id=#{params[:id]}"; end
end

describe "A controller spec", :type => :controller do
  controller_name :test_controller

  it "should include Merb::Test::Rspec::ControllerMatchers" do
    self.class.superclass.should include(Merb::Test::Rspec::ControllerMatchers)
  end

  it "should dispatch to index if calling dispatch" do
    controller = dispatch
    controller.body.should == "the index action"
  end

  it "should dispatch to show if calling dispatch(:show, :id => 5)" do
    controller = dispatch(:show, :id => 5)
    controller.body.should == "showing id=5"
  end

  it "should dispatch to foobar and mock render" do
    controller = dispatch(:foobar) do |c|
      c.should_receive(:render).and_return("mocked render")
    end
    controller.body.should == "mocked render"
    controller.assigns(:foobar).should == 42
  end

  describe "with nested describe" do
    it "should inherit the controller name" do; end
  end
end

describe TestController, :type => :controller do
  it "should not require naming the controller if describe is passed a class" do; end

  describe "with nested describe" do
    it "should inherit the controller name" do; end
  end
end