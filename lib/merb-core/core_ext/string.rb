require "pathname"

class String
  
  class InvalidPathConversion < Exception; end

  # ==== Returns
  # String:: The string with all regexp special characters escaped.
  #
  # ==== Examples
  #   "\*?{}.".escape_regexp #=> "\\*\\?\\{\\}\\."
  def escape_regexp
    Regexp.escape self
  end
  
  # ==== Returns
  # String:: The string converted to snake case.
  #
  # ==== Examples
  #   "FooBar".snake_case #=> "foo_bar"
  def snake_case
    gsub(/\B[A-Z]/, '_\&').downcase
  end

  # ==== Returns
  # String:: The string converted to camel case.
  #
  # ==== Examples
  #   "foo_bar".camel_case #=> "FooBar"
  def camel_case
    split('_').map{|e| e.capitalize}.join
  end
  
  # ==== Returns
  # String:: The path string converted to a constant name.
  #
  # ==== Examples
  #   "merb/core_ext/string".to_const_string #=> "Merb::CoreExt::String"
  def to_const_string
    gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end
  
  # ==== Returns
  # String::
  #   The path that is associated with the constantized string, assuming a
  #   conventional structure.
  #
  # ==== Examples
  #   "FooBar::Baz".to_const_path # => "foo_bar/baz"
  def to_const_path
    snake_case.gsub(/::/, "/")
  end

  # ==== Parameters
  # o<String>:: The path component to join with the string.
  #
  # ==== Returns
  # String:: The original path concatenated with o.
  #
  # ==== Examples
  #   "merb"/"core_ext" #=> "merb/core_ext"
  def /(o)
    File.join(self, o.to_s)
  end
  
  def relative_path_from(other)
    Pathname.new(self).relative_path_from(Pathname.new(other)).to_s
  end
end