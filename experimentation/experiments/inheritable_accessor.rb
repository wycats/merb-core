require "rubygems"
require "inline"

class Class
  def class_inheritable_reader(ivar)
    self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def self.#{ivar}
        return @#{ivar} if self == #{self}
        if defined?(@#{ivar})
          @#{ivar}
        else
          @#{ivar} = superclass.#{ivar}.dup
        end
      end
    RUBY
  end
    
  def class_inheritable_writer(ivar)
    self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def self.#{ivar}=(obj)
        @#{ivar} = obj        
      end
    RUBY
  end
  
  def class_inheritable_array_reader(ivar)
    self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def self.#{ivar}
        return @#{ivar} || [] if self == #{self}
        ret = [] | (@#{ivar} || []) | superclass.#{ivar}
      end
    RUBY
  end
  
  def class_inheritable_accessor(ivar)
    class_inheritable_reader(ivar)
    class_inheritable_writer(ivar)
  end
  
  def class_inheritable_array_accessor(ivar)
    class_inheritable_array_reader(ivar)
    class_inheritable_writer(ivar)
  end  
end

class Foo
end

class Bar < Foo
end

class Baz < Bar
end

class Foo
  class_inheritable_accessor(:zoo)
end

Foo.zoo = [1]
p Foo.zoo
Bar.zoo.clear
p Foo.zoo
p Bar.zoo