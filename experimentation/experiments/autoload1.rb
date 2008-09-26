autoload :Awesome, "#{File.dirname(__FILE__)}/autoload2"

Thread.new do
  Awesome.foo
end

Awesome.foo