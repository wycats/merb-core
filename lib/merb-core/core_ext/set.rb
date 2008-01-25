class Merb::SimpleSet < Hash

  def initialize(arr)
    arr.each {|x| self[x] = true}
  end
  
  def <<(value)
    self[value] = true
  end
  
  def merge(arr)
    super(arr.inject({}) {|s,x| s[x] = true; s })
  end
  
  def inspect
    "#<SimpleSet: {#{keys.map {|x| x.inspect}.join(", ")}}>"
  end
  
  alias_method :to_a, :keys

end
