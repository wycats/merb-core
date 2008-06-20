require "rubygems"
require "benchwarmer"

arr = %w(hello my name is Merb)

Benchmark.warmer(100_000) do
  report "|" do
    arr | %w(hello my name is Mrs. Merb)
  end
  report "+" do
    (arr + %w(hello my name is Mrs. Merb)).uniq
  end
end