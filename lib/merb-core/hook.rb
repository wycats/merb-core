module Merb::Hook
  
  module ClassMethods
    
    # ==== Parameters
    # mod<Module>:: The module that Merb::Hook is being extended into
    #
    # ==== Returns
    # An empty _hooks hash
    def self.extended(mod)
      mod.cattr_accessor :_hooks
      mod._hooks = Hash.new {|h,k| h[k] = Dictionary.new {|h,k| h[k] = []}}      
    end
    
    # Add a hook to the list of available hooks for the class
    # 
    # ==== Parameters
    # type<Object>:: The type of hook. Typically this would be a symbol.
    # obj<~to_s>:: A method name to call when the hook is called
    # obj<Proc>:: A proc to evaluate in the instance context when the hook is called
    # 
    # ==== Returns
    # Hash{obj => <~to_s, Proc>}:: A Hash of all the registered hooks
    def add_hook(type, obj = nil, &block)
      _hooks[type][self] << (obj || block)
    end
  end

  module InstanceMethods
    # Call all of the registered hooks for the passed in type.
    #
    # ==== Parameters
    # type<Object>:: The registered type.
    # 
    # ==== Returns
    # Array<(~to_s, Proc)> An array of all the registered hooks.
    def hook(type)
      _hooks[type].each do |klass, objs| 
        if self.is_a?(klass)
          objs.each {|obj| obj.is_a?(Proc) ? instance_eval(&obj) : send(obj) }
        end
      end
    end
  end
  
end

class Class
  
  # Make the class hookable, by giving it .add_hook and #hook
  #
  # ==== Returns
  # nil
  def is_hookable
    self.send(:extend, Merb::Hook::ClassMethods)
    self.send(:include, Merb::Hook::InstanceMethods)
    nil
  end
end