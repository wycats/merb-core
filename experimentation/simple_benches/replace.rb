require "rubygems"
require "evil"

class Object
  module InstanceExecMethods
    def rails_instance_exec(*args, &block)
      begin
        old_critical, Thread.critical = Thread.critical, true
        n = 0
        n += 1 while respond_to?(method_name = "__instance_exec#{n}")
        InstanceExecMethods.module_eval { define_method(method_name, &block) }
      ensure
        Thread.critical = old_critical
      end

      begin
        send(method_name, *args)
      ensure
        InstanceExecMethods.module_eval { remove_method(method_name) } rescue nil
      end
    end
  end
  include InstanceExecMethods
end

class Proc  
  def instance_exec(this, *args)
    begin
      old_self = self.self
      self.self = this
      self.call(*args)
    ensure
      self.self = old_self
    end
  end
end

class Foo
  def hello
    "Hello"
  end
end

# (Proc.new {|x| puts to_s(x) }).instance_exec(100, 16)
require "rubygems"
require "rbench"

p 100.rails_instance_exec(16) {|x| to_s(x) }

PROC = Proc.new {|x| to_s(x) }

RBench.run(100) do
  report("instance_exec") { PROC.instance_exec(100, 16) }
  report("rails_iexec") { 100.rails_instance_exec(16, &PROC) }
end

# p Bar.foo

# module Definer
#   def self.method_missing(meth, *args, &blk)
#     mod = Object.const_set(meth, Module.new do
#       args.each do |arg|
#         include arg
#         klass_methods = class << arg; self; end
#         extend klass_methods.as_module
#       
#         def self.new(*args)
#           obj = Object.new
#           obj.send(:extend, self)
#           obj.initialize(*args) if obj.respond_to?(:initialize)
#           obj
#         end
#       end
#       
#       @@name = meth
#       
#       def name
#         @@name
#       end
#       
#       def inspect
#         "#<#{name}:0x#{self.object_id.to_s(16)}>"
#       end
#     end)
#   end
# 
#   def self.Klass(klass, &blk)
#     klass.class_eval(&blk)
#   end
# 
#   Klass Bar() do
#     def self.awesome
#       "Awesome"
#     end
#     
#     def foo
#       "Foo"
#     end
#   end
# 
#   Klass Foo(Bar) do
#     def foo
#       super
#     end
#     
#     def bar
#       "Barzor"
#     end
#   end
#   
#   Klass Baz(Foo, Bar) do
#     
#   end
# 
#   p Baz.awesome
# end