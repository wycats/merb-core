require "rubygems"
require "rbench"
require "erb"

def using_caller(&blk)
  caller[0]
end

def evaller(&blk)
  eval("defined? _erbout", blk)
end

require "inline"

module Kernel
  inline do |builder|
    builder.include %{"env.h"}
    builder.include %{"node.h"}
    builder.add_compile_flags %{-O3}
    builder.c_raw <<-C
      VALUE c_trick() {
        return ruby_frame->prev->node->nd_file == "(erb)" ? Qtrue : Qfalse;
      }
    C
  end
end

CALLER = ERB.new("<% using_caller do %>Hello<% end %>")
EVALLER = ERB.new("<% evaller do %>Hello<% end %>")
C_TRICK = ERB.new("<% c_trick do %>Hello<% end %>")

RBench.run(10_000) do
  report("caller") { CALLER.result(binding) }
  report("evaller") { EVALLER.result(binding) }
  report("c_trick") { C_TRICK.result(binding) }
end

#                 Results |
# -------------------------
# caller            0.312 |
# evaller           0.213 |
# c_trick           0.160 |
