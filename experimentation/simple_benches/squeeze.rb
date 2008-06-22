require 'benchmark'

TIMES = (ARGV[0] || 100_000).to_i

Benchmark.bmbm do |x|
  x.report("squeeze") { TIMES.times { "abc//def//ghi//jkl".squeeze("/") }}
  x.report("gsub") { TIMES.times { "abc//def//ghi//jkl".gsub(/\/+/, "/") }}
end

# TIMES == 1_000_000
#               user     system      total        real
# squeeze   1.480000   0.010000   1.490000 (  1.491509)
# gsub      3.090000   0.010000   3.100000 (  3.107455)