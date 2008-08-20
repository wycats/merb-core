require "rubygems"
require "rbench"

def original(name, value, options)
  (@_headers['Set-Cookie'] ||=[]) << "#{name}=#{value}; " +
    options.map{|k, v| "#{k}=#{v};"}.sort.join(' ')
end

def new_impl(name, value, options)
  cookie = @_headers["Set-Cookie"] ||= []
  cookie << ("#{name}=#{value}" <<
   options.map do |k,v|
    "#{k}=#{v};"
  end.join(" "))
end

RBench.run(10_000) do
  report("original") do
    @_headers = {}
    original("foo", "bar", :foo => "bar")
  end
  
  report("new_impl") do
    @_headers = {}
    new_impl("foo", "bar", :foo => "bar")
  end
  
end