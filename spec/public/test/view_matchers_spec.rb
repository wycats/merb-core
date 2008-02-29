require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

Merb.start :environment => 'test', :log_level => :fatal

module Merb::Test::Rspec::ViewMatchers
  describe HasTag do
    describe "#matches?" do
      before(:each) do
        @document = stub(:document)
        Hpricot.should_receive(:parse).and_return @document
      end
      
      it "should should pass all found elements to the block" do
        @block_called = false
        
        @document.should_receive(:search).and_return [""]
        HasTag.new("tag").matches?("") {|e| @block_called = true}
        
        @block_called.should be_true
      end
      
      it "should not fail if the result if the block raises an error" do
        @document.should_receive(:search).and_return [""]
        HasTag.new("tag").matches?("") {|e| true.should be_false }
      end
      
      it "should not treat ExpectationNotMetError raised in the block as false" do
        @document.should_receive(:search).and_return [1, 2, 3]
        HasTag.new("tag").matches?("") {|e| e.should == 4 }.should be_false
      end
    end
    
    describe "#with_tag" do
      it "should set @inner_tag" do
        outer = HasTag.new("outer")
        inner = outer.with_tag("inner")
        
        outer.selector.should include(inner.selector)
      end
    end
    
    describe "#selector" do
      it "should always start with \/\/" do
        HasTag.new("tag").selector.should =~ /^\/\//
      end
      
      it "should use @tag for the element" do
        HasTag.new("tag").selector.should include("tag")
      end
      
      it "should use dot notation for the class" do
        HasTag.new("tag", :class => "class").selector.should include("tag.class")
      end
      
      it "should use pound(#) notation for the id" do
        HasTag.new("tag", :id => "id").selector.should include("tag#id")
      end
      
      it "should include any custom attributes" do
        HasTag.new("tag", :random => :attribute).selector.should include("[@random=\"attribute\"]")
      end
      
      it "should not include the class as a custom attribute" do
        HasTag.new("tag", :class => :my_class, :rand => :attr).selector.should_not include("[@class=\"my_class\"]")
      end
      
      it "should not include the id as a custom attribute" do
        HasTag.new("tag", :id => :my_id, :rand => :attr).selector.should_not include("[@id=\"my_id\"]")
      end
    end
    
    describe "#failure_message" do
      it "should include the tag name" do
        HasTag.new("anytag").failure_message.should include("<anytag")
      end
      
      it "should include the tag's id" do
        HasTag.new("div", :id => :spacer).failure_message.should include("<div id=\"spacer\"")
      end
      
      it "should include the tag's class" do
        HasTag.new("div", :class => :header).failure_message.should include("<div class=\"header\"")
      end
      
      it "should include the tag's custom attributes" do
        HasTag.new("h1", :attr => :val, :foo => :bar).failure_message.should include("attr=\"val\"")
        HasTag.new("h1", :attr => :val, :foo => :bar).failure_message.should include("foo=\"bar\"")
      end
    end
    
    describe "id, class, and attributes for error messages" do
      it "should start with a space for a class, id, or custom attribute" do
        HasTag.new("tag", :id => "identifier").id_for_error.should =~ /^ /
        HasTag.new("tag", :class => "classifier").class_for_error.should =~ /^ /
        HasTag.new("tag", :rand => "attr").attributes_for_error.should =~ /^ /
      end
      
      it "should have 'class=\"classifier\"' in class_for_error" do
        HasTag.new("tag", :class => "classifier").class_for_error.should include("class=\"classifier\"")
      end
      
      it "should have 'id=\"identifier\" in id_for_error" do
        HasTag.new("tag", :id => "identifier").id_for_error.should include("id=\"identifier\"")
      end
    end
  end
end