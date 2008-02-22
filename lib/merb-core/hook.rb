module Merb::Hook
  
  module ClassMethods
    
    # ==== Parameters
    # mod<Module>:: The module that Merb::Hook is being extended into.
    #
    # ==== Returns
    # Hash:: An empty hooks hash.
    def self.extended(mod)
      mod.cattr_accessor :_hooks
      mod._hooks = Hash.new {|h,k| h[k] = Dictionary.new {|h,k| h[k] = []}}      
    end
    
    # Add a hook to the list of available hooks for the class.
    # 
    # ==== Parameters
    # type<Object>:: The type of hook. Typically this would be a symbol.
    # obj<Proc, ~to_s>::
    #   A block to evaluate (Proc) or a method name to call (~to_s) when the
    #   hook is called.
    # 
    # ==== Returns
    # Hash:: A Hash of all the registered hooks.
    def add_hook(type, obj = nil, &block)
      _hooks[type][self] << (obj || block)
    end
  end

  module InstanceMethods
    # Call all of the registered hooks for the passed in type by eval'ing any
    # Procs and sending any other types to the current object.
    #
    # ==== Parameters
    # type<Object>:: The registered type.
    # 
    # ==== Returns
    # Array:: An array of all the registered hooks.
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
  
  # Make the class hookable, by giving it .add_hook and #hook.
  #
  # ==== Returns
  # Nil
  def is_hookable
    self.send(:extend, Merb::Hook::ClassMethods)
    self.send(:include, Merb::Hook::InstanceMethods)
    nil
  end
end