require "rubygems"
require "rbench"

PROC = proc { 1 + 1}
STR = "1+1"
RBench.run(100_000) do
  report("eval") { eval STR }
  report("proc") { PROC[] }
end