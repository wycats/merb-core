class Object

  # Extracts the singleton class, so that metaprogramming can be done on it.
  #
  # Let's look at two code snippets:
  #
  #   class MyString < String; end
  #
  #   MyString.instance_eval do
  #     define_method :foo do
  #       puts self
  #     end
  #   end
  #
  #   MyString.meta_class.instance_eval do
  #     define_method :bar do
  #       puts self
  #     end
  #   end
  # 
  #   def String.add_meta_var(var)
  #     self.meta_class.instance_eval do
  #       define_method var do
  #         puts "HELLO"
  #       end
  #     end
  #   end
  #
  #   MyString.new("Hello").foo  #=> "Hello"
  #   MyString.new("Hello").bar  #=> NoMethodError: undefined method `bar' for "Hello":MyString
  #   MyString.foo               #=> NoMethodError: undefined method `foo' for MyString:Class
  #   MyString.bar               #=> MyString
  #   String.bar                 #=> NoMethodError: undefined method `bar' for String:Class
  #
  #   MyString.add_meta_var(:x)
  #   MyString.x                 #=> HELLO
  #
  # As you can see, using #meta_class allows you to execute code (and here, define
  # a method) on the metaclass itself. It also allows you to define class methods that can
  # be run on subclasses, and then be able to execute code on the metaclass of the subclass
  # (here MyString).
  #
  # In this case, we were able to define a class method (add_meta_var) on String that was 
  # executable by the MyString subclass. It was then able to define a method on the subclass
  # by adding it to the MyString metaclass.
  #
  # For more information, you can check out _why's excellent article at:
  # http://whytheluckystiff.net/articles/seeingMetaclassesClearly.html
  def meta_class() class << self; self end end
  
  # Runs instance_eval on the metaclass (see Object#meta_class).
  #
  #   String.meta_eval do
  #     define_method :zoo do
  #       puts "zoo"
  #     end
  #   end
  #
  #   String.zoo # => "zoo"
  def meta_eval(&blk) meta_class.instance_eval( &blk ) end
  
  # Defines a method on the metaclass (see Object#meta_class).
  #
  #   String.meta_def :zoo do
  #     puts "zoo"
  #   end
  #
  #   String.zoo #=> "zoo"
  #
  # If the class inherits from another class, it will only be defined
  # on the direct class meta_def is called on.
  #
  #   class Foo; end
  #   class Bar < Foo; end
  #   class Baz < Foo; end
  #
  #   Bar.meta_def :q do; "Q"; end
  #   Foo.q #=> undefined method `r' for Foo:Class
  #   Bar.q #=> "Q"
  #   Baz.q #=> undefined method `r' for Baz:Class
  #
  # See Object#class_def for a comprehensive example containing meta_def
  def meta_def(name, &blk) meta_eval { define_method name, &blk } end
  
  # Defines a method on new instances of the class.
  #
  #   String.class_def :zoo do
  #     puts "zoo"
  #   end
  #
  #   "HELLO".zoo #=> "zoo"
  #
  # In combination with meta_def, you can do some pretty powerful
  # things:
  #
  # require 'merb_object'
  # class Foo
  #   def self.var
  #     @var
  #   end
  #   def self.make_var baz
  #     attr_accessor baz
  #     meta_def baz do |val|
  #       @var = val
  #     end
  #     class_def :initialize do
  #       instance_variable_set("@#{baz}", self.class.var)
  #     end
  #   end
  # end
  #
  # It might look a bit hairy, but here are some results that
  # may help:
  #
  #   class Bar < Foo
  #     make_var :foo
  #     foo "FOO"
  #   end
  #
  #   Bar.new.foo #=> "FOO"
  #
  # Essentially, what's happening is that Foo.make_var has the
  # following effects when some symbol (:foo) is passed in:
  # * Adds a new :foo accessor (returning @foo)
  # * Adds a new foo method on the **class**, allowing you to set
  #   a default value.
  # * Sets @foo to that default value when new objects are
  #   initialized.
  #
  # In the case of the Bar class, the following occurred:
  # * make_var :foo created a new :foo accessor
  # * foo "FOO" set the default value of @foo to "FOO"
  # * Bar.new created a new Bar object containing the
  #   instance variable @foo containing the default value
  #   "FOO"
  def class_def name, &blk
    class_eval { define_method name, &blk }
  end   
  
  # Returns true if:
  # * it's an empty array
  # * it's an empty string
  # * !self evaluates to true
  #
  #    [].blank?         #=>  true
  #    [1].blank?        #=>  false
  #    [nil].blank?      #=>  false
  #    nil.blank?        #=>  true
  #    true.blank?       #=>  false
  #    false.blank?      #=>  true
  #    "".blank?         #=>  true
  #    "     ".blank?    #=>  true
  #    " hey ho ".blank? #=>  false  
  def blank?
    if respond_to?(:empty?) && respond_to?(:strip)
      empty? or strip.empty?
    elsif respond_to?(:empty?)
      empty?
    else
      !self
    end
  end

  def full_const_get(name)
    list = name.split("::")
    obj = Object
    list.each {|x| obj = obj.const_get(x) }
    obj
  end
  
  # ==== Parameters
  # duck<Symbol>:: Check whether the Object respond_to?(duck)
  # duck<Class>:: Check whether the Object is_a?(duck)
  # duck<Array[Symbol, Class]>:: 
  #   Check whether it quacks_like? any of the options in the array
  def quacks_like?(duck)
    case duck
    when Symbol
      self.respond_to?(duck)
    when Class
      self.is_a?(duck)
    when Array
      duck.any? {|d| self.quacks_like?(d) }
    else
      false
    end
  end

end
