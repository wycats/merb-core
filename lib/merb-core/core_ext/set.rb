# DOC: Yehuda Katz FAILED
class Merb::SimpleSet < Hash

  # DOC: Yehuda Katz FAILED
  def initialize(arr = [])
    arr.each {|x| self[x] = true}
  end

  # DOC: Yehuda Katz FAILED
  def <<(value)
    self[value] = true
  end

  # DOC: Yehuda Katz FAILED
  def merge(arr)
    super(arr.inject({}) {|s,x| s[x] = true; s })
  end

  # DOC: Yehuda Katz FAILED
  def inspect
    "#<SimpleSet: {#{keys.map {|x| x.inspect}.join(", ")}}>"
  end
  
  alias_method :to_a, :keys

end