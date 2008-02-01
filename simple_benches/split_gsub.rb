require 'benchmark'

TIMES = (ARGV[0] || 100_000).to_i

Benchmark.bmbm do |x|
  x.report("split") { TIMES.times { "aaa/aaa/aaa.bbb.ccc.ddd".split(".").last }}
  x.report("match")  { TIMES.times { "aaa/aaa/aaa.bbb.ccc.ddd".match(/\.([^\.]*)$/)[1] }}
end

# TIMES == 1_000_000
#             user     system      total        real
# split   4.150000   0.010000   4.160000 (  4.155064)
# match   3.670000   0.000000   3.670000 (  3.683401)