module Enumerable
   
  # Abstract the common pattern of injecting a hash into a block to accumulate
  # and return the injected hash.
  #
  # Both of these are equivalent 
  #   [1,2,3].inject({}){|m,i| m[i] = i; m }
  #   [1,2,3].injecting({}){|m,i| m[i] = i }
  #   =>  {1=>1, 2=>2, 3=>3}
  #
  # The main difference is with injecting you do not have to end the block
  # with ;m to return the accumulated hash m. In this sense it is very much 
  # like Object#returning
  def injecting(s)
    inject(s) do |k, i|
      yield(k, i); k
    end
  end

  # Look for any of an array of things inside another array (or any Enumerable).
  #
  #   ['louie', 'bert'].include_any?('louie', 'chicken')
  #   => true
  def include_any?(*args)
    args.any? {|arg| self.include?(arg) }
  end

 
  #
  # Returns a hash, which keys are evaluated result from the
  # block, and values are arrays of elements in <i>enum</i>
  # corresponding to the key.
  #     
  # (1..6).group_by {|i| i%3}   #=> {0=>[3, 6], 1=>[1, 4], 2=>[2, 5]}
  #
  # This is included in Ruby 1.9
  # http://www.ruby-doc.org/core-1.9/classes/Enumerable.html#M002672
  #
  # Implementation from Ruby on Rails: 
  # trunk/activesupport/lib/active_support/core_ext/enumerable.rb 
  # [rev 5334]
  #
  def group_by
    inject({}) do |groups, element|
      (groups[yield(element)] ||= []) << element
      groups
    end
  end if RUBY_VERSION < '1.9'  
end
