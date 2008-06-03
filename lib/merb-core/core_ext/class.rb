# Copyright (c) 2004-2008 David Heinemeier Hansson
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# Allows attributes to be shared within an inheritance hierarchy, but where
# each descendant gets a copy of their parents' attributes, instead of just a
# pointer to the same. This means that the child can add elements to, for
# example, an array without those additions being shared with either their
# parent, siblings, or children, which is unlike the regular class-level
# attributes that are shared across the entire hierarchy.
class Class
  # Defines class-level and instance-level attribute reader.
  #
  # @param *syms<Array> Array of attributes to define reader for.
  # @return <Array[#to_s]> List of attributes that were made into cattr_readers
  #
  # @api public
  #
  # @todo Is this inconsistent in that it does not allow you to prevent
  #   an instance_reader via :instance_reader => false
  def cattr_reader(*syms)
    syms.flatten.each do |sym|
      next if sym.is_a?(Hash)
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        def self.#{sym}
          @@#{sym}
        end

        def #{sym}
          @@#{sym}
        end
      EOS
    end
  end

  # Defines class-level (and optionally instance-level) attribute writer.
  #
  # @param <Array[*#to_s, Hash{:instance_writer => Boolean}]> Array of attributes to define writer for.
  # @option syms :instance_writer<Boolean> if true, instance-level attribute writer is defined.
  # @return <Array[#to_s]> List of attributes that were made into cattr_writers
  #
  # @api public
  def cattr_writer(*syms)
    options = syms.last.is_a?(Hash) ? syms.pop : {}
    syms.flatten.each do |sym|
      class_eval(<<-RUBY, __FILE__, __LINE__)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        def self.#{sym}=(obj)
          @@#{sym} = obj
        end
      RUBY
      
      unless options[:instance_writer] == false
        class_eval(<<-RUBY, __FILE__, __LINE__)
          def #{sym}=(obj)
            @@#{sym} = obj
          end
        RUBY
      end
    end
  end

  # Defines class-level (and optionally instance-level) attribute accessor.
  #
  # @param *syms<Array[*#to_s, Hash{:instance_writer => Boolean}]> Array of attributes to define accessor for.
  # @option syms :instance_writer<Boolean> if true, instance-level attribute writer is defined.
  # @return <Array[#to_s]> List of attributes that were made into accessors
  #
  # @api public
  def cattr_accessor(*syms)
    cattr_reader(*syms)
    cattr_writer(*syms)
  end

  # Defines class-level inheritable attribute reader. Attributes are available to subclasses,
  # each subclass has a copy of parent's attribute.
  #
  # @param *syms<Array[#to_s]> Array of attributes to define inheritable reader for.
  # @return <Array[#to_s]> Array of attributes converted into inheritable_readers.
  #
  # @api public
  #
  # @todo Do we want to block instance_reader via :instance_reader => false
  # @todo It would be preferable that we do something with a Hash passed in
  #   (error out or do the same as other methods above) instead of silently
  #   moving on). In particular, this makes the return value of this function
  #   less useful.
  def class_inheritable_reader(*syms)
    syms.each do |sym|
      next if sym.is_a?(Hash)
      class_eval <<-EOS, __FILE__, __LINE__

        def self.#{sym}
          read_inheritable_attribute(:#{sym})
        end

        def #{sym}
          self.class.#{sym}
        end
      EOS
    end
  end

  # Defines class-level inheritable attribute writer. Attributes are available to subclasses,
  # each subclass has a copy of parent's attribute.
  #
  # @param *syms<Array[*#to_s, Hash{:instance_writer => Boolean}]> Array of attributes to
  #   define inheritable writer for.
  # @option syms :instance_writer<Boolean> if true, instance-level inheritable attribute writer is defined.
  # @return <Array[#to_s]> An Array of the attributes that were made into inheritable writers.
  #
  # @api public
  #
  # @todo We need a style for class_eval <<-HEREDOC. I'd like to make it 
  #   class_eval(<<-RUBY, __FILE__, __LINE__), but we should codify it somewhere.
  def class_inheritable_writer(*syms)
    options = syms.last.is_a?(Hash) ? syms.pop : {}
    syms.each do |sym|
      class_eval(<<-RUBY, __FILE__, __LINE__)
        def self.#{sym}=(obj)
          write_inheritable_attribute(:#{sym}, obj)
        end
      RUBY
      unless options[:instance_writer] == false
        class_eval <<-RUBY, __FILE__, __LINE__
          def #{sym}=(obj)
            self.class.#{sym} = obj
          end
        RUBY
      end
    end
  end

  # Defines class-level inheritable array writer. Arrays are available to subclasses,
  # each subclass has a copy of parent's array. Difference between other inheritable
  # attributes is that array is recreated every time it is written.
  #
  # @param *syms<Array[*#to_s, Hash{:instance_writer => Boolean}]> Array of array attribute 
  #   names to define inheritable writer for.
  # @option syms :instance_writer<Boolean> if true, instance-level inheritable array 
  #   attribute writer is defined.
  # @return <Array[#to_s]> An array of the attributes that were made into inheritable
  #   array writers.
  # 
  # @api public
  def class_inheritable_array_writer(*syms)
    options = syms.last.is_a?(Hash) ? syms.pop : {}
    syms.each do |sym|
      class_eval(<<-RUBY, __FILE__, __LINE__)
        def self.#{sym}=(obj)
          write_inheritable_array(:#{sym}, obj)
        end
      RUBY
      unless options[:instance_writer] == false
        class_eval(<<-RUBY, __FILE__, __LINE__)
          def #{sym}=(obj)
            self.class.#{sym} = obj
          end
        RUBY
      end
    end
  end

  # Defines class-level inheritable hash writer. Hashs are available to subclasses,
  # each subclass has a copy of parent's hash. Difference between other inheritable
  # attributes is that hash is recreated every time it is written.
  #
  # @param *syms<Array[*#to_s, Hash{:instance_writer => Boolean}]>:: Array of hash 
  #   attribute names to define inheritable writer for.
  # @option syms :instance_writer<Boolean>:: if true, instance-level inheritable hash
  #   attribute writer is defined.
  # @return <Array[#to_s]> An Array of attributes turned into hash_writers.
  #
  # @api public
  def class_inheritable_hash_writer(*syms)
    options = syms.last.is_a?(Hash) ? syms.pop : {}
    syms.each do |sym|
      class_eval(<<-RUBY, __FILE__, __LINE__)
        def self.#{sym}=(obj)
          write_inheritable_hash(:#{sym}, obj)
        end
      RUBY
      unless options[:instance_writer] == false
        class_eval(<<-RUBY, __FILE__, __LINE__)
          def #{sym}=(obj)
            self.class.#{sym} = obj
          end
        RUBY
      end
    end
  end

  # Defines class-level inheritable attribute accessor. Attributes are available to subclasses,
  # each subclass has a copy of parent's attribute.
  #
  # @param *syms<Array[*#to_s, Hash{:instance_writer => Boolean}]> Array of attributes to 
  #   define inheritable accessor for.
  # @option syms :instance_writer<Boolean> if true, instance-level inheritable attribute writer is defined.
  # @return <Array[#to_s]> An Array of attributes turned into inheritable accessors.
  #
  # @api public
  def class_inheritable_accessor(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_writer(*syms)
  end

  # Defines class-level inheritable array accessor. Arrays are available to subclasses,
  # each subclass has a copy of parent's array. Difference between other inheritable
  # attributes is that array is recreated every time it is written.
  #
  # @param *syms<Array[*#to_s, Hash{:instance_writer => Boolean}]> Array of array attribute 
  #   names to define inheritable accessor for.
  # @option syms :instance_writer<Boolean> if true, instance-level inheritable array
  #   attribute writer is defined.
  # @return <Array[#to_s]> An Array of attributes turned into inheritable arrays.
  # 
  # @api public
  def class_inheritable_array(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_array_writer(*syms)
  end

  # Defines class-level inheritable hash accessor. Hashs are available to subclasses,
  # each subclass has a copy of parent's hash. Difference between other inheritable
  # attributes is that hash is recreated every time it is written.
  #
  # @param *syms<Array[*#to_s, Hash{:instance_writer => Boolean}]> Array of hash attribute 
  #   names to define inheritable accessor for.
  # @option syms :instance_writer<Boolean> if true, instance-level inheritable hash 
  #   attribute writer is defined.
  # @return <Array[#to_s]> An Array of attributes turned into inheritable hashes.
  def class_inheritable_hash(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_hash_writer(*syms)
  end

  # @return <Hash> inheritable attributes hash or it's default value, new frozen Hash.
  # 
  # @api private
  def inheritable_attributes
    @inheritable_attributes ||= EMPTY_INHERITABLE_ATTRIBUTES
  end

  # Sets the attribute which copy is available to subclasses.
  #
  # @param key<#to_s> inheritable attribute name
  # @param value<not(Array, Hash)> value of inheritable attribute
  # @return <not(Array, Hash)> the value that was set
  #
  # @api private
  #
  # @note
  #   If inheritable attributes storage has it's default value,
  #   a new frozen hash, it is set to new Hash that is not frozen.
  def write_inheritable_attribute(key, value)
    if inheritable_attributes.equal?(EMPTY_INHERITABLE_ATTRIBUTES)
      @inheritable_attributes = {}
    end
    inheritable_attributes[key] = value
  end

  # Sets the array attribute which copy is available to subclasses.
  #
  # @param key<#to_s> inheritable attribute name
  # @param elements<Array> value of inheritable attribute
  # @return <Array> the Array that was set
  #
  # @api private
  #
  # @note
  #   Inheritable array is re-created on each write.
  def write_inheritable_array(key, elements)
    write_inheritable_attribute(key, []) if read_inheritable_attribute(key).nil?
    write_inheritable_attribute(key, read_inheritable_attribute(key) + elements)
  end

  # Sets the hash attribute which copy is available to subclasses.
  #
  # @param key<#to_s> inheritable attribute name
  # @param value<Hash> value of inheritable attribute
  # @return <Hash> the new hash that resulted from merging the new values
  #   with the inherited values.
  #
  # @api private
  #
  # @note
  #   Inheritable hash is re-created on each write.
  def write_inheritable_hash(key, hash)
    write_inheritable_attribute(key, {}) if read_inheritable_attribute(key).nil?
    write_inheritable_attribute(key, read_inheritable_attribute(key).merge(hash))
  end

  # Reads value of inheritable attributes.
  #
  # @param key<#to_s> the key of the attribute to read
  # @return <Object> 
  #   Inheritable attribute value. Subclasses store copies of values.
  #
  # @api private
  def read_inheritable_attribute(key)
    inheritable_attributes[key]
  end

  # Resets inheritable attributes.
  #
  # @return <Object> the empty inheritable attributes. By default, this
  #   is a frozen, empty Hash. You can override this for a class by defining
  #   EMPTY_INHERITABLE_ATTRIBUTES
  #
  # @api private
  #
  # @todo do we need this?
  def reset_inheritable_attributes
    @inheritable_attributes = EMPTY_INHERITABLE_ATTRIBUTES
  end

  private
    # Prevent this constant from being created multiple times
    EMPTY_INHERITABLE_ATTRIBUTES = {}.freeze unless const_defined?(:EMPTY_INHERITABLE_ATTRIBUTES)

    # @todo document this
    def inherited_with_inheritable_attributes(child)
      inherited_without_inheritable_attributes(child) if respond_to?(:inherited_without_inheritable_attributes)

      if inheritable_attributes.equal?(EMPTY_INHERITABLE_ATTRIBUTES)
        new_inheritable_attributes = EMPTY_INHERITABLE_ATTRIBUTES
      else
        new_inheritable_attributes = inheritable_attributes.inject({}) do |memo, (key, value)|
          memo.update(key => ((value.is_a?(Module) ? value : value.dup) rescue value))
        end
      end

      child.instance_variable_set('@inheritable_attributes', new_inheritable_attributes)
    end

    alias inherited_without_inheritable_attributes inherited
    alias inherited inherited_with_inheritable_attributes
end
