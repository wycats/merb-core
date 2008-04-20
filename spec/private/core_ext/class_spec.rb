require File.dirname(__FILE__) + '/../../spec_helper'

class ProphecyOfSmalltalk
end

describe Class, "#reset_inheritable_attributes" do
  it "resets @inheritable_attributes to empty Hash unless EMPTY_INHERITABLE_ATTRIBUTES constant is defined" do
    ProphecyOfSmalltalk.reset_inheritable_attributes

    ProphecyOfSmalltalk.instance_variable_get("@inheritable_attributes").should == {}
  end

  it "resets @inheritable_attributes to whatever Class::EMPTY_INHERITABLE_ATTRIBUTES is" do
    class Class
      EMPTY_INHERITABLE_ATTRIBUTES = { :patience => "Is a virtue" }
    end

    ProphecyOfSmalltalk.reset_inheritable_attributes

    ProphecyOfSmalltalk.instance_variable_get("@inheritable_attributes")[:patience].should == "Is a virtue"
  end
end
