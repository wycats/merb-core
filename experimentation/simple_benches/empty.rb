require "rubygems"
require "rbench"

EMPTY = []
FULL = [1, 2, 3]

RBench.run(100_000) do
  column :empty?
  column :first
  column :length
  
  report "empty" do
    empty? {EMPTY.empty?}
    first {!EMPTY.first}
    length {EMPTY.length == 0}
  end
  
  report "full" do
    empty? {FULL.empty?}
    first {!FULL.first}
    length {FULL.length == 0}
  end
end