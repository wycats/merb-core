begin
  require 'ruby2ruby'
  
  class ParseTreeArray < Array #:nodoc:
    def self.translate(*args)
      self.new(ParseTree.translate(*args))
    end
  
    def deep_array_node(type = nil)
      each do |node|
        return ParseTreeArray.new(node) if node.is_a?(Array) && (!type || node[0] == type)
        next unless node.is_a?(Array)
        return ParseTreeArray.new(node).deep_array_node(type)
      end
      nil
    end
  
    def arg_nodes
      self[1..-1].inject([]) do |sum,item|
        sum << [item] unless item.is_a?(Array)
        sum
      end
    end
    
    def get_args
      arg_node = deep_array_node(:args)
      return nil unless arg_node
      args = arg_node.arg_nodes
      default_node = arg_node.deep_array_node(:block)
      return args unless default_node
      lasgns = default_node[1..-1]
      lasgns.each do |asgn|
        args.assoc(asgn[1]) << eval(RubyToRuby.new.process(asgn[2]))
      end
      args
    end
  
  end

  # Used in mapping controller arguments to the params hash.
  # NOTE: You must have the 'ruby2ruby' gem installed for this to work.
  # Example:
  #   (In PostsController)
  #   def show(id)  #=> id is the same as params[:id]

  module GetArgs
    
    # Returns an array of method arguments and their default values
    # Example:
    #   class Example
    #     def hello(one,two="two",three)
    #     end
    #
    #     def goodbye
    #     end
    #   end
    #
    #   Example.instance_method(:hello).get_args    #=> [[:one], [:two, "two"], [:three, "three"]]
    #   Example.instance_method(:goodbye).get_args  #=> nil
    def get_args
      klass, meth = self.to_s.split(/ /).to_a[1][0..-2].split("#")
      # Remove stupidity for #<Method: Class(Object)#foo>
      klass = $` if klass =~ /\(/
      ParseTreeArray.translate(Object.const_get(klass), meth).get_args
    end
  end

  class UnboundMethod #:nodoc:
    include GetArgs
  end

  class Method  #:nodoc:
    include GetArgs
  end
rescue LoadError
end