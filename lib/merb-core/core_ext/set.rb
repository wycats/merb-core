module Merb
  class SimpleSet < Hash

    # ==== Parameters
    # arr<Array>:: Initial set values.
    def initialize(arr = [])
      arr.each {|x| self[x] = true}
    end

    # ==== Parameters
    # value<Object>:: Value to add to set.
    def <<(value)
      self[value] = true
    end

    # ==== Parameters
    # arr<Array>:: Values to merge with set.
    def merge(arr)
      super(arr.inject({}) {|s,x| s[x] = true; s })
    end

    # ==== Returns
    # String:: A human readable version of the set.
    def inspect
      "#<SimpleSet: {#{keys.map {|x| x.inspect}.join(", ")}}>"
    end
  
    alias_method :to_a, :keys
    
  end
end