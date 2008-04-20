# Allows attributes to be shared within an inheritance hierarchy, but where
# each descendant gets a copy of their parents' attributes, instead of just a
# pointer to the same. This means that the child can add elements to, for
# example, an array without those additions being shared with either their
# parent, siblings, or children, which is unlike the regular class-level
# attributes that are shared across the entire hierarchy.
class Class
  # Defines class-level and instance-level attribute reader.
  #
  # ==== Parameters
  # *syms<Array>:: Array of attributes to define reader for.
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
  # ==== Parameters
  # *syms<Array>:: Array of attributes to define writer for.
  #
  # ==== Options
  # :instance_writer<Boolean>:: if true, instance-level attribute writer is defined.
  def cattr_writer(*syms)
    options = syms.last.is_a?(Hash) ? syms.pop : {}
    syms.flatten.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        def self.#{sym}=(obj)
          @@#{sym} = obj
        end

        #{"

        def #{sym}=(obj)
          @@#{sym} = obj
        end
        " unless options[:instance_writer] == false }
      EOS
    end
  end

  # Defines class-level (and optionally instance-level) attribute accessor.
  #
  # ==== Parameters
  # *syms<Array>:: Array of attributes to define accessor for.
  #
  # ==== Options
  # :instance_writer<Boolean>:: if true, instance-level attribute writer is defined.
  def cattr_accessor(*syms)
    cattr_reader(*syms)
    cattr_writer(*syms)
  end

  # Defines class-level inheritable attribute reader. Attributes are available to subclasses,
  # each subclass has a copy of parent's attribute.
  #
  # ==== Parameters
  # *syms<Array>:: Array of attributes to define inheritable reader for.
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
  # ==== Parameters
  # *syms<Array>:: Array of attributes to define inheritable writer for.
  #
  # ==== Options
  # :instance_writer<Boolean>:: if true, instance-level inheritable attribute writer is defined.
  def class_inheritable_writer(*syms)
    options = syms.last.is_a?(Hash) ? syms.pop : {}
    syms.each do |sym|
      class_eval <<-EOS, __FILE__, __LINE__

        def self.#{sym}=(obj)
          write_inheritable_attribute(:#{sym}, obj)
        end

        #{"

        def #{sym}=(obj)
          self.class.#{sym} = obj
        end
        " unless options[:instance_writer] == false }
      EOS
    end
  end

  # Defines class-level inheritable array writer. Arrays are available to subclasses,
  # each subclass has a copy of parent's array. Difference between other inheritable
  # attributes is that array is recreated every time it is written.
  #
  # ==== Parameters
  # *syms<Array>:: Array of array attribute names to define inheritable writer for.
  #
  # ==== Options
  # :instance_writer<Boolean>:: if true, instance-level inheritable array attribute writer is defined.
  def class_inheritable_array_writer(*syms)
    options = syms.last.is_a?(Hash) ? syms.pop : {}
    syms.each do |sym|
      class_eval <<-EOS, __FILE__, __LINE__

        def self.#{sym}=(obj)
          write_inheritable_array(:#{sym}, obj)
        end

        #{"

        def #{sym}=(obj)
          self.class.#{sym} = obj
        end
        " unless options[:instance_writer] == false }
      EOS
    end
  end

  # Defines class-level inheritable hash writer. Hashs are available to subclasses,
  # each subclass has a copy of parent's hash. Difference between other inheritable
  # attributes is that hash is recreated every time it is written.
  #
  # ==== Parameters
  # *syms<Array>:: Array of hash attribute names to define inheritable writer for.
  #
  # ==== Options
  # :instance_writer<Boolean>:: if true, instance-level inheritable hash attribute writer is defined.
  def class_inheritable_hash_writer(*syms)
    options = syms.last.is_a?(Hash) ? syms.pop : {}
    syms.each do |sym|
      class_eval <<-EOS, __FILE__, __LINE__

        def self.#{sym}=(obj)
          write_inheritable_hash(:#{sym}, obj)
        end

        #{"

        def #{sym}=(obj)
          self.class.#{sym} = obj
        end
        " unless options[:instance_writer] == false }
      EOS
    end
  end

  # Defines class-level inheritable attribute accessor. Attributes are available to subclasses,
  # each subclass has a copy of parent's attribute.
  #
  # ==== Parameters
  # *syms<Array>:: Array of attributes to define inheritable accessor for.
  #
  # ==== Options
  # :instance_writer<Boolean>:: if true, instance-level inheritable attribute writer is defined.
  def class_inheritable_accessor(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_writer(*syms)
  end

  # Defines class-level inheritable array accessor. Arrays are available to subclasses,
  # each subclass has a copy of parent's array. Difference between other inheritable
  # attributes is that array is recreated every time it is written.
  #
  # ==== Parameters
  # *syms<Array>:: Array of array attribute names to define inheritable accessor for.
  #
  # ==== Options
  # :instance_writer<Boolean>:: if true, instance-level inheritable array attribute writer is defined.
  def class_inheritable_array(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_array_writer(*syms)
  end

  # Defines class-level inheritable hash accessor. Hashs are available to subclasses,
  # each subclass has a copy of parent's hash. Difference between other inheritable
  # attributes is that hash is recreated every time it is written.
  #
  # ==== Parameters
  # *syms<Array>:: Array of hash attribute names to define inheritable accessor for.
  #
  # ==== Options
  # :instance_writer<Boolean>:: if true, instance-level inheritable hash attribute writer is defined.
  def class_inheritable_hash(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_hash_writer(*syms)
  end

  # ==== Returns
  # <Hash>:: inheritable attributes hash or it's default value, new frozen Hash.
  def inheritable_attributes
    @inheritable_attributes ||= EMPTY_INHERITABLE_ATTRIBUTES
  end

  # Sets the attribute which copy is available to subclasses.
  #
  # ==== Parameters
  # key<~to_s, String, Symbol>:: inheritable attribute name
  # value<Anything but Array or Hash>:: value of inheritable attribute
  #
  # ==== Note
  # If inheritable attributes storage has it's default value,
  # a new frozen hash, it is set to new Hash that is not frozen.
  def write_inheritable_attribute(key, value)
    if inheritable_attributes.equal?(EMPTY_INHERITABLE_ATTRIBUTES)
      @inheritable_attributes = {}
    end
    inheritable_attributes[key] = value
  end

  # Sets the array attribute which copy is available to subclasses.
  #
  # ==== Parameters
  # key<~to_s, String, Symbol>:: inheritable attribute name
  # value<Array>:: value of inheritable attribute
  #
  # ==== Note
  # Inheritable array is re-created on each write.
  def write_inheritable_array(key, elements)
    write_inheritable_attribute(key, []) if read_inheritable_attribute(key).nil?
    write_inheritable_attribute(key, read_inheritable_attribute(key) + elements)
  end

  # Sets the hash attribute which copy is available to subclasses.
  #
  # ==== Parameters
  # key<~to_s, String, Symbol>:: inheritable attribute name
  # value<Hash>:: value of inheritable attribute
  #
  # ==== Note
  # Inheritable hash is re-created on each write.
  def write_inheritable_hash(key, hash)
    write_inheritable_attribute(key, {}) if read_inheritable_attribute(key).nil?
    write_inheritable_attribute(key, read_inheritable_attribute(key).merge(hash))
  end

  # Reads value of inheritable attributes.
  #
  # ==== Returns
  # Inheritable attribute value. Subclasses store copies of values.
  def read_inheritable_attribute(key)
    inheritable_attributes[key]
  end

  # Resets inheritable attributes to either EMPTY_INHERITABLE_ATTRIBUTES
  # if it is defined or it's default value, new frozen Hash.
  def reset_inheritable_attributes
    @inheritable_attributes = EMPTY_INHERITABLE_ATTRIBUTES
  end

  private
    # Prevent this constant from being created multiple times
    EMPTY_INHERITABLE_ATTRIBUTES = {}.freeze unless const_defined?(:EMPTY_INHERITABLE_ATTRIBUTES)

    def inherited_with_inheritable_attributes(child)
      inherited_without_inheritable_attributes(child) if respond_to?(:inherited_without_inheritable_attributes)

      if inheritable_attributes.equal?(EMPTY_INHERITABLE_ATTRIBUTES)
        new_inheritable_attributes = EMPTY_INHERITABLE_ATTRIBUTES
      else
        new_inheritable_attributes = inheritable_attributes.inject({}) do |memo, (key, value)|
          memo.update(key => (value.dup rescue value))
        end
      end

      child.instance_variable_set('@inheritable_attributes', new_inheritable_attributes)
    end

    alias inherited_without_inheritable_attributes inherited
    alias inherited inherited_with_inheritable_attributes
end
