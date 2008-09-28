require "rubygems"
require "rbench"

def y
  17
end
public :y

def yieldy
  yield 2
end
public :yieldy

class Proc
  def self.call
    yield 2
  end
end

PROC = proc {|x| self.y * x}

puts PROC[2]
puts 2.instance_eval(&PROC)
puts yieldy(&PROC)
puts Proc.call(2, &PROC)

RBench.run(1_000_000) do
  report("call") do
    PROC.call(2)
  end
  report("fake call") do
    Proc.call {|x| self.y * x}
  end
  report("instance_eval") do
    2.instance_eval(&PROC)
  end
  report("yield") do
    yieldy(&PROC)
  end
end