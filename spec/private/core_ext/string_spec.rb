require File.dirname(__FILE__) + '/../../spec_helper'

describe String, "to_const_string" do
  
  it "should convert a path into a constant string" do
    "foo/bar/baz_bat".to_const_string.should == "Foo::Bar::BazBat"
  end

end