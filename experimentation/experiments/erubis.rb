require "rubygems"
require "erubis"

module Erubis
  module BlockAwareEnhancer
    def add_preamble(src)
      src << "_old_buf, @_erb_buf = @_erb_buf, ''; "
    end
    
    def add_postamble(src)
      src << "\n" unless src[-1] == ?\n      
      src << "_ret = @_erb_buf; @_erb_buf = _old_buf; _ret.to_s\n"
    end
    
    def add_text(src, text)
      src << " @_erb_buf << '" << text << "'; "
    end
    
    def add_expr_escaped(src, code)
      src << ' @_erb_buf << ' << escaped_expr(code) << ';'
    end
    
    def add_expr_literal(src, code)
      unless code =~ /(do|\{)(\s*|[^|]*|)?\s*$/
        src << ' @_erb_buf << (' << code << ').to_s;'
      else
        src << ' @_erb_buf << ' << code << "; "
      end
    end
  end
  
  class BlockAwareEruby < Eruby
    include BlockAwareEnhancer
  end
end

class Context
  def capture(&blk)
    _old_buf, @_erb_buf = @_erb_buf, ""
    blk.call
    ret = @_erb_buf
    @_erb_buf = _old_buf
    ret
  end
  
  def hello
    "Hello"
  end

  def helper(&blk)
    "<tag>#{capture(&blk)}</tag>"
  end
end

puts Erubis::BlockAwareEruby.new("Begin: <%= helper do %>Hello<% end %><% 3.times do %>X<% end %><%= hello %>").src
p Erubis::BlockAwareEruby.new.process("Begin: <%= helper do %>Hello<% end %><% 3.times do %>X<% end %><%= hello %>", Context.new)