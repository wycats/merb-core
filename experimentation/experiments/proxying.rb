require "rubygems"
require "evil"

class Controller
  def testing2
    yield Builder.new(self)
  end
  
  def helper2
    testing2 do |b|
      b.awesome + awesome2
    end
  end
  
  def awesome2
    "Awesome2"
  end
end

class Controller2
  def helper
    testing do
      awesome + awesome2
    end
  end
  
  def testing
    yield
  end
  
  def method_missing(meth, *args)
    Builder.new(self).send(meth, *args)
  end
end

class Builder
  def initialize(kontroller)
    @kontroller = kontroller
  end
  
  def awesome
    "Awesome"
  end
  
  def awesome2
    "Awesome2"
  end
  
  def method_missing(meth, *args)
    self.class.class_eval <<-RUBY
    
    RUBY
    
    @kontroller.send(meth, *args)
  end
end

k = Controller.new
k2 = Controller2.new

require "rubygems"
require "rbench"

RBench.run(100_000) do
  report("with yield") do
    k.helper2
  end
  
  report("with mm") do
    k2.helper
  end
end