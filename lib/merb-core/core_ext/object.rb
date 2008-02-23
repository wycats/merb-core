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