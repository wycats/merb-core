require File.join(File.dirname(__FILE__), "spec_helper")
$:.push File.join(File.dirname(__FILE__), "fixtures")

describe Kernel, "#dependency" do
  it "works even when the BootLoader has already finished" do
    dependency "core_ext_dependency"
    defined?(CoreExtDependency).should_not be_nil
  end
end

describe Kernel, "#use_orm" do
  
  before do
    Kernel.stub!(:dependency)
    Merb.orm = :none # reset orm
  end
  
  it "should set Merb.orm" do
    Kernel.use_orm(:activerecord)
    Merb.orm.should == :activerecord
  end
  
  it "should add the the orm plugin as a dependency" do
    Kernel.should_receive(:dependency).with('merb_activerecord')
    Kernel.use_orm(:activerecord)
  end

end

describe Kernel, "#use_template_engine" do
  
  before do
    Kernel.stub!(:dependency)
    Merb.template_engine = :erb # reset orm
  end
  
  it "should set Merb.template_engine" do
    Kernel.use_template_engine(:haml)
    Merb.template_engine.should == :haml
  end
  
  it "should add merb-haml as a dependency for :haml" do
    Kernel.should_receive(:dependency).with('merb-haml')
    Kernel.use_template_engine(:haml)
  end
  
  it "should add merb-builder as a dependency for :builder" do
    Kernel.should_receive(:dependency).with('merb-builder')
    Kernel.use_template_engine(:builder)
  end
  
  it "should add no dependency for :erb" do
    Kernel.should_not_receive(:dependency)
    Kernel.use_template_engine(:erb)
  end
  
  it "should add other plugins as a dependency" do
    Kernel.should_receive(:dependency).with('merb_liquid')
    Kernel.use_template_engine(:liquid)
  end

end

describe Kernel, "#use_test" do
  
  before do
    Merb.test_framework = :rspec # reset orm
    Merb.stub!(:dependencies)
  end
  
  it "should set Merb.test_framework" do
    Kernel.use_test(:test_unit)
    Merb.test_framework.should == :test_unit
  end
  
  it "should not require test dependencies when not in 'test' env" do
    Merb.stub!(:env).and_return("development")
    Kernel.should_not_receive(:dependencies)
    Merb.use_test(:test_unit, 'hpricot', 'webrat')
  end
  
  it "should require test dependencies when in 'test' env" do
    Merb.stub!(:env).and_return("test")
    Kernel.should_receive(:dependencies).with(["hpricot", "webrat"])
    Merb.use_test(:test_unit, 'hpricot', 'webrat')
  end
  
end