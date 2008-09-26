class Awesome
  def awesome1
    1 + 1
  end

  define_method(:awesome2) do
    1 + 1
  end

  class_eval <<-RUBY
    def awesome3
      1 + 1
    end
  RUBY

  class_eval do
    def awesome4
      1 + 1
    end
  end
end

require "rubygems"
require "rbench"

OBJECT = Awesome.new

RBench.run(1000_000) do
  report("def") do
    OBJECT.awesome1
  end
  report("define_method") do
    OBJECT.awesome2
  end
  report("class_eval string") do
    OBJECT.awesome3
  end
  report("class_eval block") do
    OBJECT.awesome4
  end
end