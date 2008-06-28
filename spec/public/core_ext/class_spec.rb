require File.join(File.dirname(__FILE__), "spec_helper")

class Grandparent
end

class Parent < Grandparent
end

class Child < Parent
end

class Grandparent
  class_inheritable_accessor :last_name
end

describe Class, "#inheritable_accessor" do
  
  after :each do
    Grandparent.send(:remove_instance_variable, "@last_name") rescue nil
    Parent.send(:remove_instance_variable, "@last_name") rescue nil
    Child.send(:remove_instance_variable, "@last_name") rescue nil
  end
  
  it "inherits even if the accessor is made after the inheritance" do
    Grandparent.last_name = "Merb"
    Parent.last_name.should == "Merb"
    Child.last_name.should == "Merb"
  end
  
  it "supports ||= to change a child" do
    Parent.last_name ||= "Merb"
    Grandparent.last_name.should == nil
    Parent.last_name.should == "Merb"
    Child.last_name.should == "Merb"
  end
  
  it "supports << to change a child when the parent is an Array" do
    Grandparent.last_name = ["Merb"]
    Parent.last_name << "Core"
    Grandparent.last_name.should == ["Merb"]
    Parent.last_name.should == ["Merb", "Core"]
  end
  
  it "supports ! methods on an Array" do
    Grandparent.last_name = %w(Merb Core)
    Parent.last_name.reverse!
    Grandparent.last_name.should == %w(Merb Core)
    Parent.last_name.should == %w(Core Merb)   
  end
  
  it "support modifying a parent Hash" do
    Grandparent.last_name = {"Merb" => "name"}
    Parent.last_name["Core"] = "name"
    Parent.last_name.should == {"Merb" => "name", "Core" => "name"}
    Grandparent.last_name.should == {"Merb" => "name"}
  end
  
  it "supports hard-merging a parent Hash" do
    Grandparent.last_name = {"Merb" => "name"}
    Parent.last_name.merge!("Core" => "name")
    Parent.last_name.should == {"Merb" => "name", "Core" => "name"}
    Grandparent.last_name.should == {"Merb" => "name"}    
  end
  
  it "supports changes to the parent even if the child has already been read" do
    Child.last_name
    Grandparent.last_name = "Merb"
    Child.last_name.should == "Merb"
  end
  
  it "handles nil being set midstream" do
    Child.last_name
    Parent.last_name = nil
    Grandparent.last_name = "Merb"
    Child.last_name.should == nil
  end
  
  it "handles false being used in Parent" do
    Child.last_name
    Parent.last_name = false
    Grandparent.last_name = "Merb"
    Child.last_name.should == false
  end
  
  it "handles the grandparent changing the value (as long as the child isn't read first)" do
    Grandparent.last_name = "Merb"
    Grandparent.last_name = "Core"
    Child.last_name.should == "Core"
  end  
  
end