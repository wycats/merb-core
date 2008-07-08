require "rubygems"
require "erubis"

module Erubis
  module Basic::Converter
    def add_tailchar(src, tailchar)
    end
    
    def convert_input(src, input)
      pat = @pattern
      regexp = pat.nil? || pat == '<% %>' ? DEFAULT_REGEXP : pattern_regexp(pat)
      pos = 0
      is_bol = true     # is beginning of line
      input.scan(regexp) do |indicator, code, tailch, rspace|
        match = Regexp.last_match()
        len  = match.begin(0) - pos
        text = input[pos, len]
        pos  = match.end(0)
        ch   = indicator ? indicator[0] : nil
        lspace = ch == ?= ? nil : detect_spaces_at_bol(text, is_bol)
        is_bol = rspace ? true : false
        add_text(src, text) if text && !text.empty?
        ## * when '<%= %>', do nothing
        ## * when '<% %>' or '<%# %>', delete spaces iff only spaces are around '<% %>'
        if ch == ?=              # <%= %>
          rspace = nil if tailch && !tailch.empty?
          add_text(src, lspace) if lspace
          add_expr(src, code, indicator)
          add_text(src, rspace) if rspace
        elsif ch == ?\#          # <%# %>
          n = code.count("\n") + (rspace ? 1 : 0)
          if @trim && lspace && rspace
            add_stmt(src, "\n" * n)
          else
            add_text(src, lspace) if lspace
            add_stmt(src, "\n" * n)
            add_text(src, rspace) if rspace
          end
        elsif ch == ?%           # <%% %>
          s = "#{lspace}#{@prefix||='<%'}#{code}#{tailch}#{@postfix||='%>'}#{rspace}"
          add_text(src, s)
        else                     # <% %>
          if @trim && lspace && rspace
            if respond_to?(:add_stmt2)
              add_stmt2(src, "#{lspace}#{code}#{rspace}", tailch)
            else
              add_stmt(src, "#{lspace}#{code}#{rspace}")
            end
          else
            add_text(src, lspace) if lspace
            if respond_to?(:add_stmt2)
              add_stmt2(src, code, tailch)
            else
              add_stmt(src, code)
            end
            add_text(src, rspace) if rspace
          end
        end
      end
      #rest = $' || input                        # ruby1.8
      rest = pos == 0 ? input : input[pos..-1]   # ruby1.9
      add_text(src, rest)
    end
    
  end
  
  module BlockAwareEnhancer
    def add_preamble(src)
      src << "_old_buf, @_erb_buf = @_erb_buf, ''; "
      src << "@_engine = 'erb'; "
    end

    def add_postamble(src)
      src << "\n" unless src[-1] == ?\n      
      src << "_ret = @_erb_buf; @_erb_buf = _old_buf; _ret.to_s;\n"
    end

    def add_text(src, text)
      p escape_text(text)
      src << " @_erb_buf.concat('" << escape_text(text) << "'); "
    end

    def add_expr_escaped(src, code)
      src << ' @_erb_buf.concat(' << escaped_expr(code) << ');'
    end
    
    def add_stmt2(src, code, tailch)
      #src << code << ';'
      src << code
      src << " ).to_s; " if tailch == "="
      src << ';' unless code[-1] == ?\n
    end
    
    def add_expr_literal(src, code)
      if code =~ /(do|\{)(\s*\|[^|]*\|)?\s*\Z/
        src << ' @_erb_buf.concat( ' << code << "; "
      else
        src << ' @_erb_buf.concat((' << code << ').to_s);'
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
  
  def hello2
    "Hello"
  end

  def helper(&blk)
    "<tag>#{capture(&blk)}</tag>"
  end
end

# puts Erubis::BlockAwareEruby.new("Begin: <%= helper do %>Hello<% 3.times do %>X<% end %><% end %><%= hello %>").src
# p Erubis::BlockAwareEruby.new.process("Begin: <%= helper do %>Hello<%= 3.times do %>X<% end %><% end %><%= hello %>", Context.new)

def form_for(bar)
  bar.to_s
end

class Foo
end

# _old_verbose, $VERBOSE = $VERBOSE, nil
# Erubis::BlockAwareEruby.new("<%= form_for :foo do %>Hello<% end %>").def_method(Foo, :stuffs)
# $VERBOSE = _old_verbose
# require "parse_tree"
require "ruby_parser"
require "ruby2ruby"

text = <<-END
Pre. <p><%= form_for :field do %>
  Capturing
<% end =%>

<% if true %>Hello<% end %>
<% if false %>Goodbye<% end %>
END

p Erubis::BlockAwareEruby.new(text).src
p Erubis::BlockAwareEruby.new.process(text)

__END__
puts Erubis::BlockAwareEruby.new(<<-TEMPLATE).src
<ul id="nav">
  <% @nav_items = [] %>
  <% @nav_items << nav_item('Home', url(:root)) %>
  <% @nav_items << nav_item('Messaging', url(:new_message)) if current_user.has_permission?('message.send') %>
  <% if current_user.has_permission?('schedule.power_user') %>
    <% @nav_items << "<li>\#{link_to('Schedule', 'https://belpark.net/schedule/pwrusr/', :popup => true)}</li>" %>
  <% elsif current_user.has_permission?('schedule.view') %>
    <% @nav_items << nav_item('Schedule', 'https://belpark.net/schedule/user/calendar.php') %>
  <% end %>
  <% if current_user.emails.exists?(["emails.address LIKE ?", '%@belpark.net']) %>
    <% @nav_items << "<li>\#{link_to('Email', 'https://belpark.net/dwmail/', :popup => true)}</li>" %>
  <% end %>
  <% @nav_items << nav_item('Directory', url(:users)) if current_user.has_permission?('user.view') %>
  <%= @nav_items.join('<li class="divider">|</li>') %>
</ul>
<ul id="nav2">
  <% @nav_items = [] %>
  <% @nav_items << "<li>\#{current_user.full_name}</li>" %>
  <% @nav_items << "<li>\#{link_to('Settings', url(:edit_user, current_user.id))}</li>" if current_user.has_permission?('user.modify_self') %>
  <% @nav_items << "<li>\#{link_to 'Log Out', url(:logout), :id => 'logout'}</li>" %>
  <%= @nav_items.join('<li class="divider">|</li>') %>
</ul>
TEMPLATE