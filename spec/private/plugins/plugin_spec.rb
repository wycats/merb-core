require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

Merb.environment = 'test'

describe "Plugins", "default GENERATOR_SCOPE" do
  it "should have :merb_default first" do
    Merb.generator_scope.first.should == :merb_default
  end

  it "should have :merb" do
    Merb.generator_scope.should include(:merb)
  end

  it "should have :rspec last" do
    Merb.generator_scope.last.should == :rspec
  end
end

describe "Plugins","use_orm" do
  before(:each) do
    Merb.generator_scope.replace [:merb_default, :merb, :rspec]
    Kernel.stub!(:dependency)
  end

  it "should raise an error if use_orm is called twice" do
    use_orm(:activerecord)
    lambda { use_orm(:datamapper) }.should raise_error("Don't call use_orm more than once")
  end

  it "should not have :merb_default in GENERATOR_SCOPE with use_orm(:activerecord)" do
    use_orm(:activerecord)
    Merb.generator_scope.should_not include(:merb_default)
  end

  it "should have :activerecord in GENERATOR_SCOPE with use_orm(:activerecord)" do
    use_orm(:activerecord)
    Merb.generator_scope.should include(:activerecord)
  end

  it "should have :activerecord first in GENERATOR_SCOPE with use_orm(:activerecord)" do
    use_orm(:activerecord)
    Merb.generator_scope.first.should == :activerecord
  end

  it "should call dependency :merb_activerecord with use_orm(:activerecord)" do
    Kernel.should_receive(:dependency).with("merb_activerecord").once.
      and_return(true)
    use_orm(:activerecord)
  end
end



describe "Plugins","use_test" do
  before(:each) do
    Merb.generator_scope.replace [:merb_default, :merb, :rspec]
    Kernel.stub!(:dependency)
  end

  it "should have :rspec in GENERATOR_SCOPE by default" do
    Merb.generator_scope.should include(:rspec)
  end

  it "should not have :rspec in GENERATOR_SCOPE with use_test(:test_unit)" do
    use_test(:test_unit)
    Merb.generator_scope.should_not include(:rspec)
  end

  it "should have :test_unit in GENERATOR_SCOPE with use_test(:test_unit)" do
    use_test(:test_unit)
    Merb.generator_scope.should include(:test_unit)
  end

  it "should have :test_unit last in GENERATOR_SCOPE with use_test(:test_unit)" do
    use_test(:test_unit)
    Merb.generator_scope.last.should == :test_unit
  end

  it "should raise an error if called with an unsupported test framework" do
    lambda { use_test(:fiddlefaddle) }.should raise_error
  end
end


describe "Plugins", "register_orm" do
  before(:each) do
    Merb.generator_scope.replace [:merb_default, :merb, :rspec]
    Kernel.stub!(:dependency)
  end

  it "registers ORM plugin at generator scope" do
    register_orm(:sequel)

    Merb.generator_scope.should include(:sequel)
  end
end



# #326
describe Kernel, "#registred_orm?" do
  it "returns true if Merb.generator scope has orm alias and has not defaults flag" do
    Merb.generator_scope = [:rspec, :datamapper]

    registred_orm?(:datamapper).should be(true)
  end

  it "returns false if Merb.generator scope has defaults flag" do
    Merb.generator_scope = [:merb_default, :rspec, :datamapper]

    registred_orm?(:datamapper).should be(false)
  end
end



describe "Plugins", "register_test_framework" do
  before(:each) do
    Merb.generator_scope.replace [:merb_default, :merb, :rspec]
    Kernel.stub!(:dependency)
  end

  it "registers test framework at generator scope" do
    register_test_framework(:test_unit)

    Merb.generator_scope.should include(:test_unit)
  end
end



describe "Plugins", "supported_test_framework?" do
  before(:each) do
    Merb.generator_scope.replace [:merb_default, :merb, :rspec]
    Kernel.stub!(:dependency)
  end

  it "supports RSpec" do
    supported_test_framework?(:rspec).should be(true)
  end

  it "supports Test::Unit" do
    supported_test_framework?(:rspec).should be(true)
  end

  it "DOES NOT yet support MSpec (of Rubinius fame)" do
    supported_test_framework?(:mspec).should be(false)
  end
end
