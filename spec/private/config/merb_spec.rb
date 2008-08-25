require File.dirname(__FILE__) + '/spec_helper'

describe Merb, '#orm' do
  it "it should be :none by default" do
    Merb.orm.should == :none
  end

  it "should be changeable" do
    Merb.orm = :datamapper
    Merb.orm.should == :datamapper
  end
end

describe Merb, '#test_framework' do
  it "it should be :rspec by default" do
    Merb.test_framework.should == :rspec
  end

  it "should be changeable" do
    Merb.test_framework = :test_unit
    Merb.test_framework.should == :test_unit
  end
end

describe Merb, '#template_engine' do
  it "it should be :erb by default" do
    Merb.template_engine.should == :erb
  end

  it "should be changeable" do
    Merb.template_engine = :haml
    Merb.template_engine.should == :haml
  end
end