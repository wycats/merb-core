require 'benchmark'

TIMES = (ARGV[0] || 100_000).to_i

class Foo
  def meth1
    1
  end
end

class Bar
  (1..10_000).each do |num|
    class_eval <<-METH
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

puts Bar.new.meth10

# TIMES == 1_000_000
#               user     system      total        real
# squeeze   1.480000   0.010000   1.490000 (  1.491509)
# gsub      3.090000   0.010000   3.100000 (  3.107455)