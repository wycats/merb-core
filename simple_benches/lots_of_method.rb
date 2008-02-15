require 'benchmark'

TIMES = (ARGV[0] || 100_000).to_i

class Foo
  def meth1
    1
  end
end

class Bar
  (1..10_000).each do |num|
    class_eval <<-METH, __FILE__, __LINE__
      def meth#{num}
        #{num}
      end
    METH
  end
end

Benchmark.bmbm do |x|
  x.report("single") { TIMES.times { Foo.new.meth1 }}
  x.report("lots") { TIMES.times { Bar.new.meth1  }}
end

# TIMES == 1_000_000
#              user     system      total        real
# single   0.640000   0.000000   0.640000 (  0.638838)
# lots     0.640000   0.000000   0.640000 (  0.635349)
