require 'benchmark'
require 'zlib'

TIMES = (ARGV[0] || 100_000).to_i

Benchmark.bmbm do |x|
  x.report("instantiate") { TIMES.times { [1,2] }}
  x.report("zlib") { TIMES.times { 1.object_id + 2.object_id }}
end
