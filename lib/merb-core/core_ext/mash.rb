 
# This class has dubious semantics and we only have it so that 
# people can write params[:key] instead of params['key'] 
class Mash < Hash

  # DOC: Yehuda Katz FAILED
  def initialize(constructor = {}) 
    if constructor.is_a?(Hash) 
      super() 
      update(constructor) 
    else 
      super(constructor) 
    end 
  end

  # DOC: Yehuda Katz FAILED
  def default(key = nil) 
    if key.is_a?(Symbol) && include?(key = key.to_s) 
      self[key] 
    else 
      super 
    end 
  end 
 
  alias_method :regular_writer, :[]= unless method_defined?(:regular_writer) 
  alias_method :regular_update, :update unless method_defined?(:regular_update)

  # DOC: Yehuda Katz FAILED
  def []=(key, value) 
    regular_writer(convert_key(key), convert_value(value)) 
  end

  # DOC: Yehuda Katz FAILED
  def update(other_hash) 
    other_hash.each_pair { |key, value| regular_writer(convert_key(key), convert_value(value)) } 
    self 
  end 
 
  alias_method :merge!, :update

  # DOC: Yehuda Katz FAILED
  def key?(key) 
    super(convert_key(key)) 
  end 
 
  alias_method :include?, :key? 
  alias_method :has_key?, :key? 
  alias_method :member?, :key?

  # DOC: Yehuda Katz FAILED
  def fetch(key, *extras) 
    super(convert_key(key), *extras) 
  end

  # DOC: Yehuda Katz FAILED
  def values_at(*indices) 
    indices.collect {|key| self[convert_key(key)]} 
  end

  # DOC: Yehuda Katz FAILED
  def dup 
    Mash.new(self) 
  end

  # DOC: Yehuda Katz FAILED
  def merge(hash) 
    self.dup.update(hash) 
  end

  # DOC: Yehuda Katz FAILED
  def delete(key) 
    super(convert_key(key)) 
  end

  # DOC
  def stringify_keys!; self end

  # DOC: Yehuda Katz FAILED
  def symbolize_keys!; self end 
 
  # Convert to a Hash with String keys.

  # DOC: Yehuda Katz FAILED
  def to_hash 
    Hash.new(default).merge(self) 
  end 
 
  protected

    # DOC: Yehuda Katz FAILED
    def convert_key(key) 
      key.kind_of?(Symbol) ? key.to_s : key 
    end

    # DOC: Yehuda Katz FAILED
    def convert_value(value) 
      case value 
      when Hash 
        value.to_mash 
      when Array 
        value.collect { |e| e.is_a?(Hash) ? e.to_mash : e } 
      else 
        value 
      end 
    end
end