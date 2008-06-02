require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

describe Merb::Test::ViewHelper do
  before(:each) do
    @output = Merb::Test::ViewHelper::DocumentOutput.new(test_response)
  end
  
  describe "#tag" do
    it "should return the inner content of the first tag found by the css query" do
      tag(:li).should == "item 1"
    end
  end
  
  describe "#tags" do
    it "should return an array of tag contents for all tags found by the css query" do
      tags(:li).should include("item 1", "item 2", "item 3")
    end
  end
  
  describe "#element" do
    it "should return a raw Hpricot::Elem object for the first result found by the query" do
      Hpricot::Elem.should === element(:body)
    end
  end
  
  describe "#elements" do
    it "should return an array of Hpricot::Elem objects for the results found by the query" do
      elements("li, ul").each{|ele| Hpricot::Elem.should === ele}
    end
  end
  
  describe "#have_tag" do
    it "should work without options hash" do
      have_tag(:html)
    end
    
    it "should work with options hash" do
      have_tag(:html, {})
    end
  end
  
  describe "#get_elements" do
    it "should return an array of Hpricot::Elem objects for the results found by the query containing the filter string" do
      get_elements(:li, "item").size.should == 3
      get_elements(:li, "item 2").size.should == 1
    end
    
    it "should return an array of Hpricot::Elem objects for the results found by the query matching the filter regexp" do
      get_elements(:li, /^item \d$/).size.should == 3
      get_elements(:li, /^item (1|2)$/).size.should == 2
    end
  end
  
  it "should raise an error if the ouput is not specified and cannot be found" do
    @output, @response_output, @controller = nil
    
    lambda { tag("div") }.should raise_error("The response output was not in its usual places, please provide the output")
  end
  
  it "should use @output if no output parameter is supplied" do
    @output.should_receive(:content_for)
    
    tag(:div)
  end
  
  it "should use @output_response if no output parameter is supplied and @output does not contain output" do
    @output = nil
    @response_output = test_response
    
    tag(:div)
  end
  
  it "should use @controller.body if no output parameter is supplied and both @output and @response_output do not contain output" do
    @output, @response_output = nil
    @controller = mock(:controller)
    @controller.should_receive(:nil?).and_return false
    @controller.should_receive(:body).any_number_of_times.and_return test_response
    
    tag(:div)
  end
  
  def test_response
    <<-EOR
<html>
  <body>
    <div>Hello, World!</div>
    <ul>
      <li>item 1</li>
      <li>item 2</li>
      <li>item 3</li>
    </ul
  </body>
</html>
EOR
  end
end