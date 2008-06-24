require 'benchmark'

TIMES = (ARGV[0] || 100_000).to_i

Benchmark.bmbm do |x|
  x.report("eval 1") { TIMES.times { eval "1" }}
  x.report("eval :sym") { TIMES.times { eval ":sym" }}
  x.report("1") { TIMES.times { 1 }}
  x.report(":sym") { TIMES.times { :sym }}
end

# TIMES = 100_000
#                 user     system      total        real
# eval 1      0.170000   0.000000   0.170000 (  0.180040)
# eval :sym   0.180000   0.000000   0.180000 (  0.181182)
# 1           0.010000   0.000000   0.010000 (  0.010743)
# :sym        0.010000   0.000000   0.010000 (  0.010676)