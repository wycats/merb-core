require "minigems"
require "rbench"

class Option1A
  def initialize
    @output = ""
  end
  
  def meth
    Option1B.new.meth do
      @output << "Hello"
    end
  end
end

class Option1B
  def initialize
    @output = ""
  end
  
  def meth(&blk)
    other = eval("@output", blk)
    old, @output = @output, other
    
    old_buf = @output
    @output.replace("")
    
    yield
    
    ret = @output
    @output.replace(old_buf)
    @output = old
    ret
  end
end

class Option2A
  def initialize
    @output = ""
  end
  
  def meth
    Option2B.new.meth do
      @output << "Hello"
    end
  end
end

class Option2B
  def initialize
    @output = ""
  end
  
  def meth(&blk)
    CleanBuffer.new.instance_eval(&blk)
  end
end

class CleanBuffer
  attr_accessor :output
  def initialize
    @output = ""
  end
end

RBench.run(10_000) do
  report("eval") do
    Option1A.new.meth
  end
  report("instance_eval") do
    Option2A.new.meth
  end
end
