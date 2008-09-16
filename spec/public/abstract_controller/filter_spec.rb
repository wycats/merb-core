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
AbstractControllers = Merb::Test::Fixtures::Abstract

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
  
  it "should support proc arguments to filters when called inside a class method" do
    dispatch_should_make_body("TestProcFilterViaMethod", "onetwo")
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
  
  it "should throw an error if an unknown option is passed to a filter" do
    running { Merb::Test::Fixtures::Abstract.class_eval do
        
      class TestErrorFilter < Merb::Test::Fixtures::Abstract::Testing
        before :foo, :except => :index
      end 
    end }.should raise_error(ArgumentError, /known filter options/)
  end
  
  it "should support passing an argument to a before filter method" do
    dispatch_should_make_body("TestBeforeFilterWithArgument", "index action")
  end
  
  it "should support passing arguments to a before filter method" do
    dispatch_should_make_body("TestBeforeFilterWithArguments", "index action")
  end
  
  it "should support throwing :halt to block a filter chain" do
    dispatch_should_make_body("BeforeFilterWithThrowHalt", "Halt thrown")
  end
  
  it "should support throwing a proc in filters" do
    dispatch_should_make_body("BeforeFilterWithThrowProc", "Proc thrown")    
  end
  
  it "should raise an InternalServerError if :halt is thrown with unexpected type" do
    calling { dispatch_to(AbstractControllers::FilterChainError, :index) }.should(
      raise_error(ArgumentError, /Threw :halt, Merb. Expected String/))
  end
  
  it "should print useful HTML if throw :halt is called with nil" do
    dispatch_should_make_body("ThrowNil", 
      "<html><body><h1>Filter Chain Halted!</h1></body></html>")
  end
  
  it "should inherit before filters" do
    dispatch_should_make_body("FilterChild2", "Before Limited", :limited)
  end
    
  it "should provide benchmarks" do
    controller = dispatch_to(AbstractControllers::Benchmarking, :index)
    controller._benchmarks[:before_filters_time].should be_kind_of(Numeric)
    controller._benchmarks[:after_filters_time].should be_kind_of(Numeric)
  end
  
  it "should not get contaminated by cousins" do
    dispatch_should_make_body("FilterChild2", "Before Index")
    dispatch_should_make_body("FilterChild1", "Before Limited", :limited)
    dispatch_should_make_body("FilterChild1", " Index")
  end
end
