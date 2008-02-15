# ==== Public API
# Merb::AbstractController.before(filter<Symbol, Proc>, opts<Hash>)
# Merb::AbstractController.after(filter<Symbol, Proc>, opts<Hash>)
# Merb::AbstractController.skip_before(filter<Symbol>)
# Merb::AbstractController.skip_after(filter<Symbol>)
#
# ==== Semipublic API
# Merb::AbstractController#_body
# Merb::AbstractController#_dispatch(action<~to_s>)

require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::AbstractController, " should support before and after filters" do
    
  it "should support before filters" do
    dispatch_should_make_body("TestBeforeFilter", "foo filter")
  end
  
  it "should support after filters" do
    dispatch_should_make_body("TestAfterFilter", "foo filter")
  end
  
  it "should support skipping filters that were defined in a superclass" do
    dispatch_should_make_body("TestSkipFilter", "")
  end
  
  it "should append before filters when added" do
    dispatch_should_make_body("TestBeforeFilterOrder", "bar filter")
  end

  it "should append after filters when added" do
    dispatch_should_make_body("TestAfterFilterOrder", "bar filter")
  end
  
  it "should support proc arguments to filters evaluated in the controller's instance" do
    dispatch_should_make_body("TestProcFilter", "proc filter1 proc filter2")
  end
  
  it "should support filters that skip specific actions via :exclude" do
    dispatch_should_make_body("TestExcludeFilter", " ", :index)
    dispatch_should_make_body("TestExcludeFilter", "foo filter bar filter", :show)    
  end
  
  it "should support filters that work only on specific actions via :only" do
    dispatch_should_make_body("TestOnlyFilter", "foo filter bar filter", :index)        
    dispatch_should_make_body("TestOnlyFilter", " ", :show)
  end
  
  it "should throw an error if both :exclude and :only are passed to a filter" do
    running { Merb::Test::Fixtures::Abstract.class_eval do
      
      class TestErrorFilter < Merb::Test::Fixtures::Abstract::Testing
        before :foo, :only => :index, :exclude => :show
      end 
    end }.should raise_error(ArgumentError, /either :only or :exclude/)
  end

  it "should support filters that work only when a condition is met via :if" do
    dispatch_should_make_body("TestConditionalFilterWithMethod", "foo filter", :index, :presets => {:bar= => true})
    dispatch_should_make_body("TestConditionalFilterWithMethod", "", :index, :presets => {:bar= => false})
  end
  
  it "should support filters that work only when a condition is met via :unless" do
    dispatch_should_make_body("TestConditionalFilterWithProc", "foo filter", :index, :presets => {:bar= => 'baz'})
    dispatch_should_make_body("TestConditionalFilterWithProc", "index action", :index, :presets => {:bar= => 'bar'})
  end
  
  it "should throw an error if both :if and :unless are passed to a filter" do
    running { Merb::Test::Fixtures::Abstract.class_eval do
      
      class TestErrorFilter < Merb::Test::Fixtures::Abstract::Testing
        before :foo, :if => :index, :unless => :show
      end 
    end }.should raise_error(ArgumentError, /either :if or :unless/)
  end
  
  it "should throw an error" do
    running { dispatch_should_make_body("TestConditionalFilterWithNoProcOrSymbol", "") }.should raise_error(ArgumentError, /a Symbol or a Proc/)
  end
end