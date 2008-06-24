module Merb
  # Simple set implementation
  # on top of Hash with merging support.
  #
  # In particular this is used to store
  # a set of callable actions of controller.
  class SimpleSet < Hash

    # @param arr<Array> Initial set values.
    #
    # @return <Array> The array the Set was initialized with
    def initialize(arr = [])
      arr.each {|x| self[x] = true}
    end

    # @param value<Object> Value to add to set.
    #
    # @return <TrueClass>
    def <<(value)
      self[value] = true
    end

    # @param arr<Array> Values to merge with set.
    #
    # @return <SimpleSet> The set after the Array was merged in.
    def merge(arr)
      super(arr.inject({}) {|s,x| s[x] = true; s })
    end

    # @return <String> A human readable version of the set.
    def inspect
      "#<SimpleSet: {#{keys.map {|x| x.inspect}.join(", ")}}>"
    end

    # def to_a
    alias_method :to_a, :keys

  end # SimpleSet
end # Merb
