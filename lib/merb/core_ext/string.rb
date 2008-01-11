require 'strscan'

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

  # Concatenates a path
  #   $ "merb"/"core_ext" #=> "merb/core_ext"
  def /(o)
    File.join(self, o.to_s)
  end
end
