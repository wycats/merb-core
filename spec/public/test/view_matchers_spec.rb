require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))
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
      
        it "should pass all found elements to the block" do
          @block_called = false
        
          @document.should_receive(:search).and_return [""]
          HasTag.new("tag").matches?("") {|e| e.should == "" }
        end
      
        it 'should intercept errors raised in the block' do
          @document.should_receive(:search).and_return [""]
          lambda {
            HasTag.new("tag").matches?("") {|e| true.should be_false }
          }.should_not raise_error(Spec::Expectations::ExpectationNotMetError)
        end

        it 'should raise ExpectationNotMetError when there are no matched elements' do
          @document.should_receive(:search).and_return [""]
          lambda {
            @document.should have_tag(:tag) {|e| true.should be_false }
          }.should raise_error(Spec::Expectations::ExpectationNotMetError, "tag:\nexpected false, got true")
        end

        #part of bugfix for #329
        it 'should not raise error if block for first of matched elements by xpath expression fails' do
          @document.should_receive(:search).and_return ["a", "b"]
          lambda {
            @document.should have_tag(:tag) { |tag| tag.should == "b" }
          }.should_not raise_error(Spec::Expectations::ExpectationNotMetError)
        end
      end
    
      describe "#with_tag" do
        it "should set @outer_has_tag" do
          outer = HasTag.new("outer")
          inner = outer.with_tag("inner")
        
          inner.selector.should include(outer.selector)
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
          HasTag.new("anytag").failure_message.should include("anytag")
        end
      
        it "should include the tag's id" do
          HasTag.new("div", :id => :spacer).failure_message.should include("div#spacer")
        end
      
        it "should include the tag's class" do
          HasTag.new("div", :class => :header).failure_message.should include("div.header")
        end
      
        it "should include the tag's custom attributes" do
          HasTag.new("h1", :attr => :val, :foo => :bar).failure_message.should include("attr=\"val\"")
          HasTag.new("h1", :attr => :val, :foo => :bar).failure_message.should include("foo=\"bar\"")
        end
      end
    
      describe "id, class, and attributes for error messages" do
        it "should have '.classifier' in class_for_error" do
          HasTag.new("tag", :class => "classifier").class_for_error.should include(".classifier")
        end
      
        it "should have '#identifier' in id_for_error" do
          HasTag.new("tag", :id => "identifier").id_for_error.should include("#identifier")
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
