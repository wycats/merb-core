# Allows attributes to be shared within an inheritance hierarchy, but where each descendant gets a copy of
# their parents' attributes, instead of just a pointer to the same. This means that the child can add elements
# to, for example, an array without those additions being shared with either their parent, siblings, or
# children, which is unlike the regular class-level attributes that are shared across the entire hierarchy.
# DOC: Yehuda Katz FAILED
class Class # :nodoc:

  def cattr_reader(*syms)
    syms.flatten.each do |sym|
      next if sym.is_a?(Hash)
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        # DOC: Yehuda Katz FAILED
        def self.#{sym}
          @@#{sym}
        end

        # DOC: Yehuda Katz FAILED
        def #{sym}
          @@#{sym}
        end
      EOS
    end
  end

  # DOC: Yehuda Katz FAILED
  def cattr_writer(*syms)
    options = syms.last.is_a?(Hash) ? syms.pop : {}
    syms.flatten.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        # DOC: Yehuda Katz FAILED
        def self.#{sym}=(obj)
          @@#{sym} = obj
        end

        #{"

        # DOC: Yehuda Katz FAILED
        def #{sym}=(obj)
          @@#{sym} = obj
        end
        " unless options[:instance_writer] == false }
      EOS
    end
  end

  # DOC: Yehuda Katz FAILED
  def cattr_accessor(*syms)
    cattr_reader(*syms)
    cattr_writer(*syms)
  end

  # DOC: Yehuda Katz FAILED
  def class_inheritable_reader(*syms)
    syms.each do |sym|
      next if sym.is_a?(Hash)
      class_eval <<-EOS, __FILE__, __LINE__

        # DOC: Yehuda Katz FAILED
        def self.#{sym}
          read_inheritable_attribute(:#{sym})
        end

        # DOC: Yehuda Katz FAILED
        def #{sym}
          self.class.#{sym}
        end
      EOS
    end
  end

  # DOC: Yehuda Katz FAILED
  def class_inheritable_writer(*syms)
    options = syms.last.is_a?(Hash) ? syms.pop : {}
    syms.each do |sym|
      class_eval <<-EOS, __FILE__, __LINE__

        # DOC: Yehuda Katz FAILED
        def self.#{sym}=(obj)
          write_inheritable_attribute(:#{sym}, obj)
        end

        #{"

        # DOC: Yehuda Katz FAILED
        def #{sym}=(obj)
          self.class.#{sym} = obj
        end
        " unless options[:instance_writer] == false }
      EOS
    end
  end

  # DOC: Yehuda Katz FAILED
  def class_inheritable_array_writer(*syms)
    options = syms.last.is_a?(Hash) ? syms.pop : {}
    syms.each do |sym|
      class_eval <<-EOS, __FILE__, __LINE__

        # DOC: Yehuda Katz FAILED
        def self.#{sym}=(obj)
          write_inheritable_array(:#{sym}, obj)
        end

        #{"

        # DOC: Yehuda Katz FAILED
        def #{sym}=(obj)
          self.class.#{sym} = obj
        end
        " unless options[:instance_writer] == false }
      EOS
    end
  end

  # DOC: Yehuda Katz FAILED
  def class_inheritable_hash_writer(*syms)
    options = syms.last.is_a?(Hash) ? syms.pop : {}
    syms.each do |sym|
      class_eval <<-EOS, __FILE__, __LINE__

        # DOC: Yehuda Katz FAILED
        def self.#{sym}=(obj)
          write_inheritable_hash(:#{sym}, obj)
        end

        #{"

        # DOC: Yehuda Katz FAILED
        def #{sym}=(obj)
          self.class.#{sym} = obj
        end
        " unless options[:instance_writer] == false }
      EOS
    end
  end

  # DOC: Yehuda Katz FAILED
  def class_inheritable_accessor(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_writer(*syms)
  end

  # DOC: Yehuda Katz FAILED
  def class_inheritable_array(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_array_writer(*syms)
  end

  # DOC: Yehuda Katz FAILED
  def class_inheritable_hash(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_hash_writer(*syms)
  end

  # DOC: Yehuda Katz FAILED
  def inheritable_attributes
    @inheritable_attributes ||= EMPTY_INHERITABLE_ATTRIBUTES
  end

  # DOC: Yehuda Katz FAILED
  def write_inheritable_attribute(key, value)
    if inheritable_attributes.equal?(EMPTY_INHERITABLE_ATTRIBUTES)
      @inheritable_attributes = {}
    end
    inheritable_attributes[key] = value
  end

  # DOC: Yehuda Katz FAILED
  def write_inheritable_array(key, elements)
    write_inheritable_attribute(key, []) if read_inheritable_attribute(key).nil?
    write_inheritable_attribute(key, read_inheritable_attribute(key) + elements)
  end

  # DOC: Yehuda Katz FAILED
  def write_inheritable_hash(key, hash)
    write_inheritable_attribute(key, {}) if read_inheritable_attribute(key).nil?
    write_inheritable_attribute(key, read_inheritable_attribute(key).merge(hash))
  end

  # DOC: Yehuda Katz FAILED
  def read_inheritable_attribute(key)
    inheritable_attributes[key]
  end

  # DOC: Yehuda Katz FAILED
  def reset_inheritable_attributes
    @inheritable_attributes = EMPTY_INHERITABLE_ATTRIBUTES
  end
  
  private
    # Prevent this constant from being created multiple times
    EMPTY_INHERITABLE_ATTRIBUTES = {}.freeze unless const_defined?(:EMPTY_INHERITABLE_ATTRIBUTES)

    # DOC: Yehuda Katz FAILED
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