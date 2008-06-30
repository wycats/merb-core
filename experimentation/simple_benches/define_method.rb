require 'benchmark'

TIMES = (ARGV[0] || 100_000).to_i

class Foo
  define_method(:foo) do |x|
    x
  end

  class_eval <<-EOS, __FILE__, __LINE__

    def #{:bar}(x)
      x
    end
  EOS

  def baz(x)
    x
  end
end

Benchmark.bmbm do |x|
  x.report("define_method") { TIMES.times {Foo.new.foo(10)} }
  x.report("class_eval") { TIMES.times {Foo.new.bar(10)} }
  x.report("def") { TIMES.times {Foo.new.baz(10)} }  
end