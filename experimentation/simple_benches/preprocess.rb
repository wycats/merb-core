require "rubygems"
require "rbench"

require "erubis"
require "erubis/preprocessing"

def link_to(contents, url)
  "<a href='#{url}'>#{contents}</a>"
end

class Templates
end

REGULAR_TEXT = %{<%= link_to("w00t", "http://www.example.com") %>}
Erubis::Eruby.new(REGULAR_TEXT).def_method(Templates, "regular")

PREPROCESSED_TEXT = %{[%= link_to("w00t", "http://www.example.com") %]}
pre_text = Erubis::PreprocessingEruby.new(nil).process(PREPROCESSED_TEXT)
Erubis::Eruby.new(pre_text).def_method(Templates, "preprocessed")

TEMPLATES = Templates.new

p Templates.new.preprocessed
p Templates.new.regular

RBench.run(1_000_000) do
  report("regular") do
    TEMPLATES.regular()
  end
  
  report("preprocessed") do
    TEMPLATES.preprocessed()
  end
end