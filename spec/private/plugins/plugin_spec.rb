require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

Merb.environment = 'test'

def reset_merb_generator_scope
  Merb.orm_generator_scope = :merb_default
  Merb.test_framework_generator_scope = :rspec
  Kernel.stub!(:dependency)
end

describe "Plugins", "default generator scope" do
  it "has :merb_default" do
    Merb.generator_scope.should include(:merb_default)
  end

  it "MUST include :merb" do
    Merb.generator_scope.should include(:merb)
  end

  it "has :rspec" do
    Merb.generator_scope.should include(:rspec)
  end
end



describe "Plugins", "ORM generator scope" do
  before :each do
    reset_merb_generator_scope
  end

  it "has merb_default stub by default" do
    Merb.orm_generator_scope.should == :merb_default
  end
end



describe "Plugins","use_orm" do
  before(:each) do
    reset_merb_generator_scope
  end

  it "removes defaults from generator scope" do
    use_orm(:datamapper)
    Merb.generator_scope.should_not include(:merb_default)
  end

  it "adds orm symbol to generator scope" do
    use_orm(:activerecord)
    Merb.generator_scope.should include(:activerecord)
  end

  it "replaces previously used if use_orm is called more than once" do
    use_orm(:sequel)
    use_orm(:activerecord)
    use_orm(:datamapper)

    Merb.generator_scope.should_not include(:sequel)
    Merb.generator_scope.should_not include(:activerecord)
    Merb.generator_scope.should include(:datamapper)
  end

  it "calls dependency :merb_<orm>" do
    Kernel.should_receive(:dependency).with("merb_activerecord").once.
      and_return(true)
    use_orm(:activerecord)
  end

  it "does not affect presence of :merb in generator scope" do
    use_orm(:datamapper)
    Merb.generator_scope.should include(:merb)
  end
end



describe "Plugins", "test framework generator scope" do
  before :each do
    reset_merb_generator_scope
  end

  it "has rspec by default" do
    Merb.test_framework_generator_scope.should == :rspec
  end
end



describe "Plugins","use_test" do
  before(:each) do
    reset_merb_generator_scope
  end

  it "removes defaults" do
    use_test(:test_unit)
    Merb.generator_scope.should_not include(:rspec)
  end

  it "adds used test framework to generator scope" do
    use_test(:test_unit)
    Merb.generator_scope.should include(:test_unit)
  end

  it "raises an error when unsupported test framework is used" do
    lambda { use_test(:fiddlefaddle) }.should raise_error
  end

  it "does not affect presence of :merb in generator scope" do
    use_test(:test_unit)
    Merb.generator_scope.should include(:merb)
  end
end



describe "Plugins", "register_orm" do
  before(:each) do
    reset_merb_generator_scope
  end

  it "registers ORM plugin at orm generator scope" do
    register_orm(:sequel)

    Merb.orm_generator_scope.should == :sequel
  end
end



describe "Plugins", "register_test_framework" do
  before(:each) do
    reset_merb_generator_scope
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

  it "does not (no yet) support MSpec" do
    supported_test_framework?(:mspec).should be(false)
  end

  it "does not (no yet) support Bacon" do
    supported_test_framework?(:bacon).should be(false)
  end
end
