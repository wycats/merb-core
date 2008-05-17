require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require "merb-core/test"

Merb.start :environment => 'test', :log_level => :fatal

describe Merb::Test::Rspec::ViewMatchers do
  include Merb::Test::ViewHelper
  
  before(:each) do
    @body = <<-EOF
    <div id='main'>
      <div class='inner'>hello, world!</div>
    </div>
    EOF
  end
  
  describe "#match_tag" do
    it "should work with a HasContent matcher in the block" do
      @body.should have_tag(:div) {|d| d.should_not contain("merb")}
    end
    
    it "should work with a 'with_tag' chain" do
      @body.should have_tag(:div, :id => :main).with_tag(:div, :class => 'inner')
    end
    
    it "should work with a block before a with_tag" do
      @body.should have_tag(:div, :id => :main) {|d| d.should_not contain("merb")}.with_tag(:div, :class => 'inner')
    end
  end

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
      
        it "should not intercept any errors raised in the block" do
          @document.should_receive(:search).and_return [""]
          lambda {
            HasTag.new("tag").matches?("") {|e| true.should be_false }
          }.should raise_error(Spec::Expectations::ExpectationNotMetError)
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
    
    describe HasContent do
      before(:each) do
        @element = stub(:element)
        @element.stub!(:inner_text).and_return <<-EOF
          <div id='main'>
            <div class='inner'>hello, world!</div>
          </div>
        EOF
        
        @element.stub!(:contains?)
        @element.stub!(:matches?)
      end
      
      describe "#matches?" do
        it "should call element#contains? when the argument is a string" do
          @element.should_receive(:contains?)
          
          HasContent.new("hello, world!").matches?(@element)
        end
        
        it "should call element#matches? when the argument is a regular expression" do
          @element.should_receive(:matches?)
          
          HasContent.new(/hello, world/).matches?(@element)
        end
      end
    
      describe "#failure_message" do
        it "should include the content string" do
          hc = HasContent.new("hello, world!")
          hc.matches?(@element)
          
          hc.failure_message.should include("\"hello, world!\"")
        end
        
        it "should include the content regular expresson" do
          hc = HasContent.new(/hello,\sworld!/)
          hc.matches?(@element)
          
          hc.failure_message.should include("/hello,\\sworld!/")
        end
        
        it "should include the element's inner content" do
          hc = HasContent.new(/hello,\sworld!/)
          hc.matches?(@element)
          
          hc.failure_message.should include(@element.inner_text)
        end
      end
    end
  end
end
