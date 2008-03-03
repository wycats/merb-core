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
    lambda { use_orm(:datamapper) }.should raise_error
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