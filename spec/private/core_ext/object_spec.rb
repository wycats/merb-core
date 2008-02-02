require File.dirname(__FILE__) + '/../../spec_helper'
class Foo
  
  def self.make_meth

    class_def :foo do
      "Hello"
    end
  end
end

describe Object do

  it "should use class_def to define a method on the class of an object" do
    Foo.make_meth
    Foo.new.foo.should == "Hello"
  end
  
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