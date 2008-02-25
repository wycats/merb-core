module Merb
  class SimpleSet < Hash

    # ==== Parameters
    # arr<Array>:: Initial set values.
    #
    # ==== Returns
    # Array:: The array the Set was initialized with
    def initialize(arr = [])
      arr.each {|x| self[x] = true}
    end

    # ==== Parameters
    # value<Object>:: Value to add to set.
    #
    # ==== Returns
    # true
    def <<(value)
      self[value] = true
    end

    # ==== Parameters
    # arr<Array>:: Values to merge with set.
    #
    # ==== Returns
    # SimpleSet:: The set after the Array was merged in.
    def merge(arr)
      super(arr.inject({}) {|s,x| s[x] = true; s })
    end

    # ==== Returns
    # String:: A human readable version of the set.
    def inspect
      "#<SimpleSet: {#{keys.map {|x| x.inspect}.join(", ")}}>"
    end
  
    # def to_a
    alias_method :to_a, :keys
    
  end
end