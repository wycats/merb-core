class Foo
  private
  def bar
    "Hey"
  end
  
  protected
  def baz
    "HeyHey"
  end
end

class Bar < Foo
  def call_bar
    bar
  end
  
  def call_bar_proxy
    Foo.new.bar
  end
  
  def call_baz
    baz
  end
  
  def call_baz_proxy
    Foo.new.baz
  end
end

p Bar.new.call_bar
p Bar.new.call_baz
p Bar.new.call_baz_proxy
p Bar.new.call_bar_proxy

# "Hey"
# "HeyHey"
# "HeyHey"
# experimentation/experiments/protected.rb:19:in `call_bar_proxy': private method `bar' called for #<Foo:0x28780> (NoMethodError)
#   from experimentation/experiments/protected.rb:34
