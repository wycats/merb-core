require "rubygems"
require "rbench"
require "erb"
require "erubis"

module Erubis
  module BlockAwareEnhancer
    def add_preamble(src)
      src << "@_buf = '';"
    end    

    def add_postamble(src)
      src << "\n" unless src[-1] == ?\n
      src << "_buf\n"
    end
    
    def add_expr_literal(src, code)
      unless code =~ /(do|\{)(\s*|[^|]*|)?\s*$/
        src << ' _buf << (' << code << ').to_s;'
      else
        src << ' _buf << ' << code << "; "
      end
    end    
  end
  
  class BlockAwareEruby < Eruby
    include BlockAwareEnhancer
  end
end


class Templates
  attr_accessor :_buf
end

ERB.new("<%= 1 %><%= 2 %><%= 3 %>").def_method(Templates, "erb")
Erubis::Eruby.new("<%= 1 %><%= 2 %><%= 3 %>").def_method(Templates, "erubis")

p ERB.new("<%= 1 %><%= 2 %><%= 3 %>")
p Erubis::BlockAwareEruby.new("<%= 1 %><%= 2 %><%= 3 %>")

T = Templates.new

p T.erb
p T.erubis

RBench.run(1_000_000) do
  report("erb") do
    T.erb
  end
  report("erubis") do
    T.erubis
  end
end