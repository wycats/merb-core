template = <<-HTML
  <div>
    <%= hello %>
    <% [1,2,3,4,5,6,7,8,9,10].each do |i| %>
    <%= i %>
    <% end %>
  </div>
  <h3>Hello</h3>
  <p>My name is testie McTesterson</p>
  
  <div>
    <%= hello %>
    <% [1,2,3,4,5,6,7,8,9,10].each do |i| %>
    <%= i %>
    <% end %>
  </div>
  <h3>Hello</h3>
  <p>My name is testie McTesterson</p>

  <div>
    <%= hello %>
    <% [1,2,3,4,5,6,7,8,9,10].each do |i| %>
    <%= i %>
    <% end %>
  </div>
  <h3>Hello</h3>
  <p>My name is testie McTesterson</p>

  <div>
    <%= hello %>
    <% [1,2,3,4,5,6,7,8,9,10].each do |i| %>
    <%= i %>
    <% end %>
  </div>
  <h3>Hello</h3>
  <p>My name is testie McTesterson</p>

  <div>
    <%= hello %>
    <% [1,2,3,4,5,6,7,8,9,10].each do |i| %>
    <%= i %>
    <% end %>
  </div>
  <h3>Hello</h3>
  <p>My name is testie McTesterson</p>  
HTML

module Foo
end

require "benchmark"
require "rubygems"
require "erubis"
TIMES = (ARGV[0] || 100_000).to_i

Benchmark.bmbm do |x|
  x.report("Compiling") do
    TIMES.times { ::Erubis::Eruby.new(template).def_method(Foo, "template") }
  end
end