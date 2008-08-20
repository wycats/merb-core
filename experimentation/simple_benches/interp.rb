require "rubygems"
require "rbench"

PROC = proc {|text| "Hello my name is #{text}"}

def meth(text)
  "Hello my name is #{text}"
end

RBench.run(1_000_000) do
  report("interpolation") do
    merb = "Merb"
    "Hello my name is #{merb}"
  end
  report("proc") do
    merb = "Merb"
    PROC[merb]
  end
  
  report("meth") do
    merb = "Merb"
    meth(merb)
  end
end