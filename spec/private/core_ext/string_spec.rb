require File.dirname(__FILE__) + '/../../spec_helper'

describe String, "#to_const_string" do

  it "should convert a path into a constant string" do
    "foo/bar/baz_bat".to_const_string.should == "Foo::Bar::BazBat"
  end

end



describe String, "#camel_case" do
  it "handles lowercase without underscore" do
    "merb".camel_case.should == "Merb"
  end

  it "handles lowercase with 1 underscore" do
    "merb_core".camel_case.should == "MerbCore"
  end

  it "handles lowercase with more than 1 underscore" do
    "so_you_want_contribute_to_merb_core".camel_case.should == "SoYouWantContributeToMerbCore"
  end

  it "handles lowercase with more than 1 underscore in a row" do
    "__python__is__like__this".camel_case.should == "PythonIsLikeThis"
  end

  it "handle first capital letter with underscores" do
    "Python__Is__Like__This".camel_case.should == "PythonIsLikeThis"
  end

  it "leaves CamelCase as is" do
    "TestController".camel_case.should == "TestController"
  end
end
