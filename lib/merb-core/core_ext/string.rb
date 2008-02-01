require 'strscan'
# DOC: Yehuda Katz FAILED
class String
  
  # DOC: Yehuda Katz FAILED
  class InvalidPathConversion < Exception; end

  # Escapes any characters in the string that would have special meaning in a 
  # regular expression.
  #   $ "\*?{}.".escape_regexp #=> "\\*\\?\\{\\}\\."

  def escape_regexp
    Regexp.escape self
  end
  
  # "FooBar".snake_case #=> "foo_bar"

  # DOC: Yehuda Katz FAILED
  def snake_case
    gsub(/\B[A-Z]/, '_\&').downcase
  end

  # "foo_bar".camel_case #=> "FooBar"

  # DOC: Yehuda Katz FAILED
  def camel_case
    split('_').map{|e| e.capitalize}.join
  end
  
  # "merb/core_ext/string" #=> "Merb::CoreExt::String"
  # 
  # About 50% faster than string.split('/').map{ |s| s.camel_case }.join('::')

  def to_const_string
    new_string = ""
    input = StringScanner.new(self.downcase)
    until input.eos?
      if input.scan(/([a-z][a-zA-Z\d]*)(_|$|\/)/)
        new_string << input[1].capitalize
        new_string << "::" if input[2] == '/'
      else
        raise InvalidPathConversion, self
      end
    end
    new_string
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

  # DOC: Yehuda Katz FAILED
  def /(o)
    File.join(self, o.to_s)
  end
end