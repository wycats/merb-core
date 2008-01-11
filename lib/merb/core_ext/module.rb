class Module
  
  # alias_method_chain :foo, :bar produces the following pattern:
  # 
  #   alias_method :foo_without_bar, :foo
  #   alias_method :foo, :foo_with_bar
  #
  # You will then need to write the foo_with_bar method, which will
  # be able to reference foo_without_bar:
  #
  # def foo_with_bar
  #   foo_without_bar.map {|x| x + 1 }
  # end
  # 
  # Method punctuation (foo? and foo!) will be retained:
  #
  # alias_method_chain :foo?, :bar will produce:
  #   foo_without_bar?
  #   foo_with_bar?
  #
  # alias_method_chain :foo!, :bar will produce:
  #   foo_without_bar!
  #   foo_with_bar!
  def alias_method_chain(target, feature)
    # Strip out punctuation on predicates or bang methods since
    # e.g. target?_without_feature is not a valid method name.
    aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
    yield(aliased_target, punctuation) if block_given?
    alias_method "#{aliased_target}_without_#{feature}#{punctuation}", target
    alias_method target, "#{aliased_target}_with_#{feature}#{punctuation}"
  end
  
  # defines a series of instance variables to be initialized when
  # the class is initialized.
  #
  # For instance, you could create the class Foo:
  #
  #   class Foo
  #     attr_initialize :bar, :baz
  #     attr_accessor   :bar, :baz
  #   end
  #
  # and initialize an instance of the class as follows:
  #
  #   Foo.new(1, 2)
  #
  # which will create a new Foo object with #bar equal to 1 and #baz
  # equal to 2.
  #
  # Passing a different number of arguments to <tt>new</tt> than you
  # passed to attr_initialize will result in an ArgumentError being 
  # thrown. 
  def attr_initialize(*attrs)
    define_method(:initialize) do |*passed|
      raise ArgumentError, "Wrong number of arguments" \
        unless attrs.size == passed.size
  
      attrs.each_with_index do |att, i|
        instance_variable_set("@#{att}", passed[i])
      end
  
      after_initialize if respond_to? :after_initialize
    end
  end

  
end