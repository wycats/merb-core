# ==== Methodology
# Each of the controllers tested here tests a discrete, single case. This
# is to ensure that each test is actually testing exactly what we want,
# and that other features (or lack thereof), are not causing tests to fail
# that would otherwise pass.
module Merb::Test::Fixtures
  
  module Abstract
    
    class Testing < Merb::AbstractController
      self._template_root = File.dirname(__FILE__) / "views"
    end

    class TestBeforeFilter < Testing
      before :foo

      def index
        "#{@x}"
      end
      
      private
      
      def foo
        @x = "foo filter"
      end    
    end

    class TestAfterFilter < Testing
      after :foo

      def index
        "index action"
      end
      
      private
      
      def foo
        @body = "foo filter"
      end        
    end

    class TestSkipFilter < TestBeforeFilter
      skip_before :foo
    end

    class TestBeforeFilterOrder < TestBeforeFilter
      before :bar

      def index
        "#{@x}"
      end
    
      private
      
      def bar
        @x = "bar filter"
      end
    end

    class TestAfterFilterOrder < TestAfterFilter
      after :bar

      def index
        "index action"
      end
    
      private
      
      def bar
        @body = "bar filter"
      end
    end

    class TestProcFilter < Testing
      before { @x = "proc filter1" }
      before Proc.new { @y = "proc filter2" }

      def index
        "#{@x} #{@y}"
      end
    end
    
    class TestProcFilterViaMethod < Testing
      def self.my_before(data)
        before proc { add_string(data) }
      end
      
      my_before("one")
      my_before("two")

      def index
        @text
      end
      protected
        def add_string(str)
          @text ||= ""
          @text << str
        end
    end

    class TestExcludeFilter < Testing
      before :foo, :exclude => :index
      before :bar, :exclude => [:index]

      def index
        "#{@x} #{@y}"
      end

      def show
        "#{@x} #{@y}"
      end
    
      private
      
      def foo
        @x = "foo filter"
      end

      def bar
        @y = "bar filter"
      end
    end

    class TestOnlyFilter < Testing
      before :foo, :only => :index
      before :bar, :only => [:index]

      def index
        "#{@x} #{@y}"
      end

      def show
        "#{@x} #{@y}"
      end
    
      private
      
      def foo
        @x = "foo filter"
      end

      def bar
        @y = "bar filter"
      end
    end
    
    class TestConditionalFilterWithMethod < Testing
      before  :foo, :if => :bar
      
      attr_accessor :bar
      
      def index
        "#{@x}"
      end
      
      private
      def foo
        @x = "foo filter"
      end
    end
    
    class TestConditionalFilterWithProc < Testing
      after   :foo, :unless => lambda { |x| x.bar == "bar" }
      
      attr_accessor :bar
      
      def index
        "index action"
      end
      
      private
      def foo
        @body = "foo filter"
      end
    end
    
    class TestConditionalFilterWithNoProcOrSymbol < Testing
      after   :foo, :unless => true
      
      def index
        "index action"
      end
    end
    
    class TestBeforeFilterWithArgument < Testing
      before :foo, :with => "bar"
      
      def index
        "index action"
      end
      
      private
      def foo(bar)
        bar == "bar"
      end
    end
    
    class TestBeforeFilterWithArguments < Testing
      before :foo, :with => ["bar", "baz"]
      
      def index
        "index action"
      end
      
      private
      def foo(bar,baz)
        bar == "bar" && baz == "baz"
      end
    end
    
    class BeforeFilterWithThrowHalt < Testing
      before do
        throw :halt, "Halt thrown"
      end
      
      def index
        "Halt not thrown"
      end      
    end
    
    class BeforeFilterWithThrowProc < Testing
      before do
        throw :halt, Proc.new { "Proc thrown" }
      end
      
      def index
        "Proc not thrown"
      end
    end
    
    class ThrowNil < Testing
      before do
        throw :halt, nil
      end
      
      def index
        "Awesome"
      end
    end
    
    class FilterChainError < Testing
      before do
        throw :halt, Merb
      end
      
      def index
        "Awesome"
      end
    end
    
    class Benchmarking < Testing
      before {}
      after {}
      
      def index
        "Awesome"
      end
    end
  end
end