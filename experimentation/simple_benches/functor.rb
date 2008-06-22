require "rubygems"
require "functor"

require "rbench"

fib_func = Functor.new do
  given( 0 ) { 0 }
  given( 1 ) { 1 }
  given( Integer ) { |n| self.call( n - 1 ) + self.call( n - 2 ) }
end

correct_func = Functor.new do
  given( 0 ) { 0 }
  given( 1 ) { 1 }
  given( lambda { |n| n > 1 } ) { |n| self.call( n - 1 ) + self.call( n - 2 ) }
end

def fib(n)
  return 0 if n == 0
  return 1 if n == 1
  return fib(n - 1) + fib(n - 2) if n.is_a?(Integer) && n > 1
  raise "You need to provide an integer"
end

RBench.run(1) do
  group("fib(20)") do
    report "functor" do
      fib_func.call(20)
    end
    report "more correct functor" do
      correct_func.call(20)
    end
    report "function" do
      fib(20)
    end
  end
  group("[1..10].map fib", 10) do
    report "functor" do
      [ *0..10 ].map( &fib_func )
    end
    report "more correct functor" do
      [ *0..10 ].map( &correct_func )
    end
    report "function" do
      [ *0..10 ].map {|x| fib(x) }
    end
  end
end