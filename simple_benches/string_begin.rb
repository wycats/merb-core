require "rubygems"
require "rbench"

RBench.run(10_000) do
  report "string =~" do
    "text/html, foo/bar, baz/bat" =~ %r{^text/html}
  end
  
  report "string[0..8]" do
    "text/html"[0..8] == "text/html"
  end
end