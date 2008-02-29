require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

class TestController < Merb::Controller
  def get(id = nil); end
  def post; end
end

describe Merb::Test::RouteHelper do
  before(:each) do
    Merb::Router.prepare do |r|
      r.match("/", :method => :get).to(:controller => "test_controller", :action => "get").name(:getter)
      r.match("/", :method => :post).to(:controller => "test_controller", :action => "post")
      r.match("/:id").to(:controller => "test_controller", :action => "get").name(:with_id)
    end
  end
  
  describe "#url" do
    it "should use Merb::Router" do
      url(:getter).should == "/"
    end
    
    it "should work with a model as the parameter" do
      model = mock(:model)
      model.stub!(:id).and_return("123")
      url(:with_id, model).should == "/123"
    end
    
    it "should work with a parameters hash" do
      url(:with_id, :id => 123).should == "/123"
    end
  end
  
  describe "#request_to" do
    it "should GET if no method is given" do
      request_to("/")[:action].should == "get"
    end
    
    it "should return a hash" do
      Hash.should === request_to("/")
    end
    
    it "should contain the controller in the result" do
      request_to("/")[:controller].should == "test_controller"
    end
    
    it "should contain the action in the result" do
      request_to("/")[:action].should == "get"
    end
    
    it "should contain any parameters in the result" do
      request_to("/123")[:id].should == "123"
    end
  end
end