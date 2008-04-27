require File.dirname(__FILE__) + '/../../spec_helper'
class Foo
end


describe Object do
  it "should treat an empty string as blank" do
    "".should be_blank
  end

  it "should treat a string with just spaces as blank" do
    "   ".should be_blank
  end

  it "should treat an empty array as blank" do
    [].should be_blank
  end

  it "should treat boolean false as blank" do
    false.should be_blank
  end
end



describe Object, "#quacks_like" do
  it "use respond_to? to determine quacks_like :symbol" do
    "Foo".should be_quacks_like(:strip)
  end

  it "should return true if any of the elements in the Array are true" do
    "Foo".should be_quacks_like([String, Array])
  end

  it "should return false if an invalid value is passed in" do
    "Foo".should_not be_quacks_like({})
  end
end



describe Object, "#full_const_get" do
  class April
    class In
      class Paris
        PERFORMER = "Ella Fitzgerald"
      end
    end
  end

  module Succubus
    module In
      module Rapture
        PERFORMER = "Dimmu Borgir"
      end
    end
  end

  it "returns constant corresponding to the name" do
    self.full_const_get("April").should == April
  end

  it "handles nested classes" do
    self.full_const_get("April::In::Paris").should == April::In::Paris
  end

  it "handles nested modules" do
    self.full_const_get("Succubus::In::Rapture").should == Succubus::In::Rapture
  end

  it "handles in-scoped constants in modules" do
    self.full_const_get("Succubus::In::Rapture::PERFORMER").should == "Dimmu Borgir"
  end

  it "handles in-scoped constants in classes" do
    self.full_const_get("April::In::Paris::PERFORMER").should == "Ella Fitzgerald"
  end

  it "acts as a global function" do
    lambda { April::In::Paris.full_const_get("PERFORMER") }.should raise_error(NameError)
  end

  it "raises an exception if constant is undefined" do
    lambda { self.full_const_get("We::May::Never::Meet::Again") }.should raise_error(NameError)
  end
end



describe Object, "#make_module" do
  it "defines module from a string name" do
    Object.make_module("Cant::Take::That::Away::From::Me")

    defined?(Cant::Take::That::Away::From::Me).should == "constant"
  end

  it "is OK if module already defined" do
    module Merb
      module Is
        module Modular
        end
      end
    end

    lambda { Object.make_module("Merb::Is::Modular") }.should_not raise_error
  end
end

describe Object, "#in?" do
  it "should be true if the argument includes self" do
    4.in?([1,2,4,5]).should be_true
  end
  
  it "should be false if the argument does not include self" do
    4.in?([1,2,3,5]).should be_false
  end
  
  it "should splat the args so [] are not required" do
    4.in?(1,2,3,4,5).should be_true
  end
end
