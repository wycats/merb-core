class Foo
  def initialize
    @original = method(:foo)
  end
  
  def foo(i)
    i + 1
  end

  def bar1
    i = 0
    while i < 1_000
      foo(i)
      i += 1
    end
  end

  def bar2
    if method(:foo) == @original
      i = 0
      while i < 1_000
        i + 1
        i += 1
      end
    else
      i = 0
      while i < 1_000
        foo(i)
        i += 1
      end
    end
  end
end

Foo.new.bar1
Foo.new.bar2

FOO = Foo.new

require "rubygems"
require "rbench"

RBench.run(1_000) do
  report("regular") do
    FOO.bar1
  end
  
  report("inlined") do
    FOO.bar2
  end
end