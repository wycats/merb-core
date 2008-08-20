require "rubygems"
require "rbench"

def caught
  catch(:halt) { yield }
end

def child
  redirect(url)
end

def redirect(url)
  throw(:halt, ...)
end

def returned
  return yield
end

def return_redirect(url)
  return ...
end

def return_child
  return "Hello"
  
end

RBench.run(1_000_000) do
  report("catch") do
    caught { child }
  end
  report("returned") do
    returned { return_child }
  end
  report("catch with return") do
    caught { "Hello" }
  end
end