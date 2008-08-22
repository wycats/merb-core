require "rubygems"
require "rbench"

RBench.run(1_000_000) do
  report("threequals") do
    String === nil
  end
  report("is_a?") do
    nil.is_a?(Class)
  end
end