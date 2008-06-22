require "rubygems"
require "erubis"

module Erubis
  module BlockAwareEnhancer
    def add_preamble(src)
      src << "@_buf = '';"
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

class Context
  def _buf
    @_buf ||= ""
  end

  def capture(&blk)
    _old_buf, @_buf = @_buf, ""
    blk.call
    ret = @_buf
    @_buf = _old_buf
    ret
  end

  def helper(&blk)
    "<tag>#{capture(&blk)}</tag>"
  end
end

p Erubis::BlockAwareEruby.new.process("Begin: <%= helper do %>Hello<% end %><% 3.times do %>X<% end %>", Context.new)