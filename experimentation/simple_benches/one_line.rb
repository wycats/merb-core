require "rubygems"
require "benchwarmer"

x = true

Benchmark.warmer(10_000_000) do
  report("multiline") { if x; true; end }
  report("one-liner") { true if x }
end