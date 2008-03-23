module Merb::InlineTemplates
end

module Merb::Template
  
  EXTENSIONS  = {} unless defined?(EXTENSIONS)
  METHOD_LIST = {} unless defined?(METHOD_LIST)
  MTIMES      = {} unless defined?(MTIMES)
  
  class << self
    # Get the template's method name from a full path. This replaces
    # non-alphanumeric characters with __ and "." with "_"
    #
    # Collisions are potentially possible with something like:
    # ~foo.bar and __foo.bar or !foo.bar.
    #
    # ==== Parameters
    # path<String>:: A full path to convert to a valid Ruby method name
    #
    # ==== Returns
    # String:: The template name.
    #
    #---
    # We might want to replace this with something that varies the
    # character replaced based on the non-alphanumeric character
    # to avoid edge-case collisions.
    def template_name(path)
      path = File.expand_path(path)      
      path.gsub(/[^\.a-zA-Z0-9]/, "__").gsub(/\./, "_")
    end

    # Get the name of the template method for a particular path.
    #
    # ==== Parameters
    # path<String>:: A full path to find a template method for.
    # template_stack<Array>:: The template stack. Not used.
    #
    # ==== Returns
    # DOC
    #---
    # @semipublic
    def template_for(path, template_stack = [])
      path = File.expand_path(path)
      
      ret = 
      if Merb::Config[:reload_templates]
        file = Dir["#{path}.{#{Merb::Template::EXTENSIONS.keys.join(',')}}"].first
        METHOD_LIST[path] = file ? inline_template(file) : nil
      else
        METHOD_LIST[path] ||= begin
          file = Dir["#{path}.{#{Merb::Template::EXTENSIONS.keys.join(',')}}"].first          
          file ? inline_template(file) : nil
        end
      end
      
      ret
    end
    
    # Takes a template at a particular path and inlines it into a module and
    # adds it to the METHOD_LIST table to speed lookup later.
    # 
    # ==== Parameters
    # path<String>::
    #   The full path of the template (minus the templating specifier) to
    #   inline.
    # mod<Module>::
    #   The module to put the compiled method into. Defaults to
    #   Merb::InlineTemplates
    #
    # ==== Note
    # Even though this method supports inlining into any module, the method
    # must be available to instances of AbstractController that will use it.
    #---
    # @public
    def inline_template(path, mod = Merb::InlineTemplates)
      path = File.expand_path(path)
      METHOD_LIST[path.gsub(/\.[^\.]*$/, "")] = 
        engine_for(path).compile_template(path, template_name(path), mod)
    end
    
    # Finds the engine for a particular path.
    # 
    # ==== Parameters
    # path<String>:: The path of the file to find an engine for.
    #
    # ==== Returns
    # Class:: The engine.
    #---
    # @semipublic
    def engine_for(path)
      path = File.expand_path(path)      
      EXTENSIONS[path.match(/\.([^\.]*)$/)[1]]
    end
    
    # Registers the extensions that will trigger a particular templating
    # engine.
    # 
    # ==== Parameters
    # engine<Class>:: The class of the engine that is being registered
    # extensions<Array[String]>:: 
    #   The list of extensions that will be registered with this templating
    #   language
    #
    # ==== Raises
    # ArgumentError:: engine does not have a compile_template method.
    #
    # ==== Example
    #   Merb::Template.register_extensions(Merb::Template::Erubis, ["erb"])
    #---
    # @public
    def register_extensions(engine, extensions) 
      raise ArgumentError, "The class you are registering does not have a compile_template method" unless
        engine.respond_to?(:compile_template)
      extensions.each{|ext| EXTENSIONS[ext] = engine }
      Merb::AbstractController.class_eval <<-HERE
        include #{engine}::Mixin
      HERE
    end
  end
  
  require 'erubis'

  class Erubis    
    # ==== Parameters
    # path<String>:: A full path to the template.
    # name<String>:: The name of the method that will be created.
    # mod<Module>:: The module that the compiled method will be placed into.
    def self.compile_template(path, name, mod)
      template = ::Erubis::Eruby.new(File.read(path))
      template.def_method(mod, name, path) 
      name
    end

    module Mixin
      
      # Provides direct acccess to the buffer for this view context
      #
      # ==== Parameters
      # the_binding<Binding>:: The binding to pass to the buffer.
      #
      # ==== Returns
      # DOC
      def _erb_buffer( the_binding )
        @_buffer = eval( "_buf", the_binding, __FILE__, __LINE__)
      end

      # ==== Parameters
      # *args:: Arguments to pass to the block.
      # &block:: The template block to call.
      #
      # ==== Returns
      # String:: The output of the block.
      #
      # ==== Examples
      # Capture being used in a .html.erb page:
      # 
      #   <% @foo = capture do %>
      #     <p>Some Foo content!</p> 
      #   <% end %>
      def capture_erb(*args, &block)
        # get the buffer from the block's binding
        buffer = _erb_buffer( block.binding ) rescue nil

        # If there is no buffer, just call the block and get the contents
        if buffer.nil?
          block.call(*args)
        # If there is a buffer, execute the block, then extract its contents
        else
          pos = buffer.length
          block.call(*args)

          # extract the block
          data = buffer[pos..-1]

          # replace it in the original with empty string
          buffer[pos..-1] = ''

          data
        end
      end

      # DOC
      def concat_erb(string, binding)
        _erb_buffer(binding) << string
      end
            
    end
  
    Merb::Template.register_extensions(self, %w[erb])    
  end
  
end

module Erubis
  module RubyEvaluator

    # DOC
    def def_method(object, method_name, filename=nil)
      m = object.is_a?(Module) ? :module_eval : :instance_eval
      setup = "@_engine = 'erb'"
      object.__send__(m, "def #{method_name}(locals={}); #{setup}; #{@src}; end", filename || @filename || '(erubis)')
    end
   
  end
end