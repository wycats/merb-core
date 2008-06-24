require 'benchmark'

TIMES = (ARGV[0] || 10_000).to_i

Benchmark.bmbm do |x|
  x.report("instance_methods.include? == true") do
    TIMES.times do
      Class.instance_methods.include?(:to_s) || Class.instance_methods.include?("to_s")
    end
  end
  x.report("instance_method() rescue nil == true") do
    TIMES.times do    
      Class.instance_method(:to_s) rescue false
    end
  end
  x.report("instance_methods.include? == false") do
    TIMES.times do    
      Class.instance_methods.include?(:foo) || Class.instance_methods.include?("foo")
    end
  end
  x.report("instance_method() rescue nil == false") do
    TIMES.times do    
      Class.instance_method(:foo) rescue false
    end
  end  
end

# TIMES = 10_000
#                                           user     system      total        real
# instance_methods.include? == true     1.790000   0.010000   1.800000 (  1.805433)
# intance_method() rescue nil == true   0.010000   0.000000   0.010000 (  0.008334)
# instance_methods.include? == false    1.810000   0.000000   1.810000 (  1.818613)
# intance_method() rescue nil == true   0.130000   0.010000   0.140000 (  0.135678)