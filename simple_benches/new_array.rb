require "rubygems"
require "rbench"

SYM = {:sym => [:sym]}

RBench.run(100_000) do
  report "[1]" do
    [:sym]
  end
  
  report "hash" do
    SYM[:sym]
  end
end