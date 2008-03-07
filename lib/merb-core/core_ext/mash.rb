# This class has dubious semantics and we only have it so that people can write
# params[:key] instead of params['key'].
class Mash < Hash

  # ==== Parameters
  # constructor<Object>::
  #   The default value for the mash. Defaults to an empty hash.
  #
  # ==== Alternatives
  # If constructor is a Hash, a new mash will be created based on the keys of
  # the hash and no default value will be set.
  def initialize(constructor = {}) 
    if constructor.is_a?(Hash) 
      super() 
      update(constructor) 
    else 
      super(constructor) 
    end 
  end

  # ==== Parameters
  # key<Object>:: The default value for the mash. Defaults to nil.
  #
  # ==== Alternatives
  # If key is a Symbol and it is a key in the mash, then the default value will
  # be set to the value matching the key.
  def default(key = nil) 
    if key.is_a?(Symbol) && include?(key = key.to_s) 
      self[key] 
    else 
      super 
    end 
  end 
 
  alias_method :regular_writer, :[]= unless method_defined?(:regular_writer) 
  alias_method :regular_update, :update unless method_defined?(:regular_update)

  # ==== Parameters
  # key<Object>:: The key to set. This will be run through convert_key.
  # value<Object>::
  #   The value to set the key to.  This will be run through convert_value.
  def []=(key, value) 
    regular_writer(convert_key(key), convert_value(value)) 
  end

  # ==== Parameters
  # other_hash<Hash>::
  # A hash to update values in the mash with. The keys and the values will be
  # converted to Mash format.
  #
  # ==== Returns
  # Mash:: The updated mash.
  def update(other_hash) 
    other_hash.each_pair { |key, value| regular_writer(convert_key(key), convert_value(value)) } 
    self 
  end 
 
  alias_method :merge!, :update

  # ==== Parameters
  # key<Object>:: The key to check for. This will be run through convert_key.
  #
  # ==== Returns
  # Boolean:: True if the key exists in the mash.
  def key?(key) 
    super(convert_key(key)) 
  end 

  # def include? def has_key? def member?
  alias_method :include?, :key? 
  alias_method :has_key?, :key? 
  alias_method :member?, :key?

  # ==== Parameters
  # key<Object>:: The key to fetch. This willbe run through convert_key.
  # extras:: Default value.
  #
  # ==== Returns
  # Object:: The value at key or the default value.
  def fetch(key, *extras) 
    super(convert_key(key), *extras) 
  end

  # ==== Parameters
  # indices<Array>::
  #   The keys to retrieve values for. These will be run through convert_key.
  def values_at(*indices) 
    indices.collect {|key| self[convert_key(key)]} 
  end

  # ==== Returns
  # Mash:: A duplicate of this mash.
  def dup 
    Mash.new(self) 
  end

  # ==== Parameters
  # hash<Hash>:: The hash to merge with the mash.
  #
  # ==== Returns
  # Mash:: A new mash with the hash values merged in.
  def merge(hash) 
    self.dup.update(hash) 
  end

  # ==== Parameters
  # key<Object>::
  #   The key to delete from the mash. This will be run through convert_key.
  def delete(key) 
    super(convert_key(key)) 
  end

  # Used to provide the same interface as Hash.
  #
  # ==== Returns
  # Mash:: This mash unchanged.
  def stringify_keys!; self end
 
  # ==== Returns
  # Hash:: The mash as a Hash with string keys.
  def to_hash 
    Hash.new(default).merge(self) 
  end 
 
  protected
  # ==== Parameters
  # key<Object>:: The key to convert.
  #
  # ==== Returns
  # Object::
  #   The converted key. If the key was a symbol, it will be converted to a
  #   string.
  def convert_key(key) 
    key.kind_of?(Symbol) ? key.to_s : key 
  end

  # ==== Parameters
  # value<Object>:: The value to convert.
  #
  # ==== Returns
  # Object::
  #   The converted value. A Hash or an Array of hashes, will be converted to
  #   their Mash equivalents.
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