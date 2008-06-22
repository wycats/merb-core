require 'set'
require 'benchmark'
require 'forwardable'

TIMES = (ARGV[0] || 100_000).to_i

hsh = {:x => true, :y => true}
set = Set.new([:x, :y])
fst = FasterSet.new([:x, :y])

Benchmark.bmbm do |x|
  x.report("current included") { TIMES.times { hsh[:x] } }
  x.report("hash included") { TIMES.times { hsh.include?(:x) } }
  x.report("set included") { TIMES.times { set.include?(:x) } }  
  x.report("fasterset included") { TIMES.times { fst.include?(:x) } }  
  x.report("current !included") { TIMES.times { hsh[:z] } }  
  x.report("hash !included") { TIMES.times { hsh.include?(:z) } }
  x.report("set !included") { TIMES.times { set.include?(:z) } }    
  x.report("fasterset !included") { TIMES.times { fst.include?(:z) } }      
end

# TIMES = 1_000_000
#                           user     system      total        real
# current included      0.400000   0.000000   0.400000 (  0.400513)
# hash included         0.390000   0.000000   0.390000 (  0.396909)
# set included          1.060000   0.000000   1.060000 (  1.055078)
# fasterset included    0.400000   0.000000   0.400000 (  0.401823)
# current !included     0.510000   0.000000   0.510000 (  0.508479)
# hash !included        0.400000   0.000000   0.400000 (  0.400109)
# set !included         1.050000   0.010000   1.060000 (  1.062367)
# fasterset !included   0.400000   0.000000   0.400000 (  0.399415)