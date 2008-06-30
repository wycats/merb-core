require 'benchmark'

TIMES = (ARGV[0] || 100_000).to_i

Benchmark.bmbm do |x|
  x.report("'.' true") { TIMES.times { "Hello.Goodbye".index(".") }}
  x.report("/\./ true") { TIMES.times { "Hello.Goodbye".index(/\./) }}
  x.report("'.' false") { TIMES.times { "HellooGoodbye".index(".") }}
  x.report("/\./ false") { TIMES.times { "HellooGoodbye".index(/\./) }}      
end