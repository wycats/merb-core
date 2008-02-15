require 'benchmark'

TIMES = (ARGV[0] || 100_000).to_i

hsh = {:controller => "foo", :action => "bar", :mime => "baz", :type => "bat"}
prock = proc {|hsh| "#{hsh[:controller]}/#{hsh[:action]}.#{hsh[:mime]}.#{hsh[:type]}" } 
evall = "\"\#{hsh[:controller]}/\#{hsh[:action]}.\#{hsh[:mime]}.\#{hsh[:type]}\""
gsubb = ":controller/:action.:mime.:type"

def meth(hsh)
  "#{hsh[:controller]}/#{hsh[:action]}.#{hsh[:mime]}.#{hsh[:type]}"
end

Benchmark.bmbm do |x|
  x.report("proc") do
    TIMES.times do
      prock.call(hsh)
    end
  end
  
  x.report("eval") do
    TIMES.times do
      eval evall, binding, __FILE__, __LINE__
    end
  end
  
  x.report("gsub") do
    TIMES.times do
      gsubb.gsub(/(:controller|:action|:mime|:type)/) {|g| hsh[g[1..-1].to_sym] }
    end
  end
  
  x.report("meth") do
    TIMES.times do
      meth(hsh)
    end
  end
  
end

# TIMES == 100_000
#            user     system      total        real
# proc   0.350000   0.000000   0.350000 (  0.346125)
# eval   1.400000   0.000000   1.400000 (  1.407556)
# gsub   1.330000   0.000000   1.330000 (  1.325826)
# meth   0.320000   0.000000   0.320000 (  0.320849)