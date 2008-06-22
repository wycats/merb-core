require "rubygems"
require "rbench"

# arr = %w(hello my name is Merb)
# 
# Benchmark.warmer(100_000) do
#   report "|" do
#     arr | %w(hello my name is Mrs. Merb)
#   end
#   report "+" do
#     (arr + %w(hello my name is Mrs. Merb)).uniq
#   end
# end

require "set"
HSH = {:foo => true, :bar => true, :baz => true}
SET = Set.new
SET << :foo << :bar << :baz

def included?(key)
  HSH.include?(key)
end

RBench.run(1_000_000) do
  column :hash
  column :set
  column :indirection
  
  report "includes" do
    hash { HSH.include?(:foo) }
    set { SET.include?(:foo) }
    indirection { included?(:foo) }
  end
  
  report "not included" do
    hash { HSH.include?(:bam) }
    set { SET.include?(:bam) }
    indirection { included?(:bam) }
  end
end

#              Results |
# ----------------------
# hash           0.078 |
# set            0.171 |
