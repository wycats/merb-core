require "pathname"

class String
  
  ##
  # @return <String> The string with all regexp special characters escaped.
  #
  # @example
  #   "*?{}.".escape_regexp #=> "\\*\\?\\{\\}\\."
  def escape_regexp
    Regexp.escape self
  end
  
  ##
  # @return String The string with all regexp special characters unescaped.
  #
  # @example
  #   "\\*\\?\\{\\}\\.".unescape_regexp #=> "*?{}."
  def unescape_regexp
    self.gsub(/\\([\.\?\|\(\)\[\]\{\}\^\$\*\+\-])/, '\1')
  end
  
  ##
  # @return <String> The string converted to snake case.
  #
  # @example
  #   "FooBar".snake_case #=> "foo_bar"
  # @example
  #   "HeadlineCNNNews".snake_case #=> "headline_cnn_news"
  # @example
  #   "CNN".snake_case #=> "cnn"
  def snake_case
    return self.downcase if self =~ /^[A-Z]+$/
    self.gsub(/([A-Z]+)(?=[A-Z][a-z]?)|\B[A-Z]/, '_\&') =~ /_*(.*)/
      return $+.downcase
  end

  ##
  # @return <String> The string converted to camel case.
  #
  # @example
  #   "foo_bar".camel_case #=> "FooBar"
  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end

  ##
  # @return <String> The path string converted to a constant name.
  #
  # @example
  #   "merb/core_ext/string".to_const_string #=> "Merb::CoreExt::String"
  def to_const_string
    gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end

  ##
  # @return <String>
  #   The path that is associated with the constantized string, assuming a
  #   conventional structure.
  #
  # @xample
  #   "FooBar::Baz".to_const_path # => "foo_bar/baz"
  def to_const_path
    snake_case.gsub(/::/, "/")
  end

  ##
  # @param o<String> The path component to join with the string.
  #
  # @return <String> The original path concatenated with o.
  #
  # @example
  #   "merb"/"core_ext" #=> "merb/core_ext"
  def /(o)
    File.join(self, o.to_s)
  end

  ##
  # @param other<String> Base path to calculate against
  #
  # @return <String> Relative path from between the two
  #
  # @example
  #   "/opt/local/lib".relative_path_from("/opt/local/lib/ruby/site_ruby") # => "../.."
  def relative_path_from(other)
    Pathname.new(self).relative_path_from(Pathname.new(other)).to_s
  end
  
end
