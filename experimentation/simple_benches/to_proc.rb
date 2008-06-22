require "benchmark"
class Symbol
  def to_proc
    lambda { |value| value.send(self) }
  end
end

class Array
  def map_on(sym)
     self.map {|x| x.send(sym)}
  end
end

small_arr = [0,1,2,3,4]
large_arr = (0...2_000).to_a
TIMES = ARGV[0] ? ARGV[0].to_i : 10_000

Benchmark.bm(30) do |x|
  x.report("Symbol#to_proc (small)") do
    TIMES.times do
      small_arr.map(&:nonzero?)
    end
  end
  
  # x.report("Symbol#to_proc (large)") do
  #   TIMES.times do
  #     large_arr.map(&:nonzero?)
  #   end
  # end
  
  x.report("map_on (small)") do
    TIMES.times do
      small_arr.map_on(:nonzero?)
    end
  end
  
  # x.report("map_on (large)") do
  #   TIMES.times do
  #     large_arr.map_on(:nonzero?)
  #   end
  # end
  
  x.report("raw (small)") do
    TIMES.times do
      small_arr.map {|y| y.nonzero?}
    end
  end
  
  # x.report("raw (large)") do
  #   TIMES.times do
  #     large_arr.map {|y| y.nonzero?}
  #   end
  # end
end