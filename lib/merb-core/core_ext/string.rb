class String
  
  class InvalidPathConversion < Exception; end

  # Escapes any characters in the string that would have special meaning in a 
  # regular expression.
  #   $ "\*?{}.".escape_regexp #=> "\\*\\?\\{\\}\\."
  def escape_regexp
    Regexp.escape self
  end
  
  # "FooBar".snake_case #=> "foo_bar"
  def snake_case
    gsub(/\B[A-Z]/, '_\&').downcase
  end

  # "foo_bar".camel_case #=> "FooBar"
  def camel_case
    split('_').map{|e| e.capitalize}.join
  end
  
  # "merb/core_ext/string" #=> "Merb::CoreExt::String"
  def to_const_string
    gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end
  
  # Converts "FooBar::Baz" to "foo_bar/baz". Useful for converting constants
  # into their associated paths assuming a conventional structure.
  #
  # ==== Returns
  # String:: The path that is associated with the constantized string
  def to_const_path
    snake_case.gsub(/::/, "/")
  end

  # Concatenates a path
  #   $ "merb"/"core_ext" #=> "merb/core_ext"
  def /(o)
    File.join(self, o.to_s)
  end
end