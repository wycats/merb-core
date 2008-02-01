require File.dirname(__FILE__) + '/../../spec_helper'

describe Merb::SimpleSet do
  
  before do
    @s = Merb::SimpleSet.new("Foo")
  end
  
  it "should support <<" do
    @s << "Hello"
    @s.should be_include("Hello")
  end
  
  it "should support merge" do
    @s.should include("Foo")
    @t = @s.merge(["Bar"])
    @t.should be_kind_of(Merb::SimpleSet)
    @t.should include("Foo")
    @t.should include("Bar")    
  end
  
  it "should support inspect" do
    @s.inspect.should == "#<SimpleSet: {\"Foo\"}>"
  end
  
end