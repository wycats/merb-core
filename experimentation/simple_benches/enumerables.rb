require "rubygems"
require "rbench"

def range_to_ary(rng)
  rng.inject([]) do |memo, i|
    memo.push(i)
    memo
  end
end

ary1000 = range_to_ary(0..1000)
ary100 = range_to_ary(0..100)
ary50 = range_to_ary(0..50)
ary20 = range_to_ary(0..20)
ary10 = range_to_ary(0..10)
ary5 = range_to_ary(0..5)
ary3 = range_to_ary(0..3)
ary2 = range_to_ary(0..2)
ary1 = range_to_ary(0..1)

def for_i_in_x_and_memo(ary)
  memo = []
  for i in ary
    # add some noise
    memo << (i.to_s.gsub(/\d/, i.to_s))
  end
  memo
end

def each_and_memo(ary)
  memo = []
  ary.each do |i|
    # add some noise
    memo << (i.to_s.gsub(/\d/, i.to_s))
  end
  memo
end

def plain_inject(ary)
  ary.inject([]) do |memo, i|
    # add some noise
    memo << (i.to_s.gsub(/\d/, i.to_s))
    memo
  end
end

for ary in [ary1000, ary100, ary50, ary20, ary10, ary5, ary3, ary2, ary1]
  puts '*' * 72
  puts "Number of items: #{ary.size}"
  RBench.run(2_000) do
    report "each with external memo" do
      each_and_memo(ary)
    end

    report "for i in x with external memo" do
      for_i_in_x_and_memo(ary)
    end  
    
    report "inject" do
      plain_inject(ary)
    end
  end
end
