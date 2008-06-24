require "rubygems"
require "rbench"

SIMPLE = "text/html"
QUAL = "text/html ; q= 0.5"

RBench.run(100_000) do
  column :original
  column :capture
  
  report("simple") do
    original { SIMPLE.split(/;\s*q=/).map{|a| a.strip } }
    capture do
      SIMPLE =~ /\s*([^;\s]*)\s*(;\s*q=\s*(.*))?/
      [$1, $3]
    end
  end

  report("qual") do
    original { QUAL.split(/;\s*q=/).map{|a| a.strip } }
    capture do
      QUAL =~ /\s*([^;\s]*)\s*(;\s*q=\s*(.*))?/
      [$1, $3]
    end
  end
  
end