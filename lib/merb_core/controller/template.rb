module Merb::Template
  
  EXTENSIONS  = {} unless defined?(EXTENSIONS)
  METHOD_LIST = {} unless defined?(METHOD_LIST)
  
  class << self
    # Get the template's method name from a full path. This replaces
    # non-alphanumeric characters with __ and "." with "_"
    #
    # Collisions are potentially possible with something like:
    # ~foo.bar and __foo.bar or !foo.bar.
    #
    # ==== Parameters
    # path<String>:: A full path to convert to a valid Ruby method
    #                name
    #---
    # We might want to replace this with something that varies the
    # character replaced based on the non-alphanumeric character
    # to avoid edge-case collisions.
    def template_name(path)
      path.gsub(/[^\.a-zA-Z0-9]/, "__").gsub(/\./, "_")
    end
    
    # Takes a template at a particular path and inlines it into
    # a module, which defaults to Merb::GlobalHelper
    #
    # This also takes the full path, minus its templating specifier
    # and adds it to the METHOD_LIST table to speed lookup later
    # 
    # ==== Parameters
    # path<String>:: The full path of the template to inline
    # mod<Module>:: The module to put the compiled method into
    #
    # ==== Note
    # Even though this method supports inlining into any module,
    # the method must be available to instances of AbstractController
    # that will use it.
    #---
    # @public
    def inline_template(path, mod = Merb::GlobalHelper)
      METHOD_LIST[path.gsub(/\.[^\.]*$/, "")] = 
        engine_for(path).compile_template(path, template_name(path), mod)
    end
    
    # Finds the engine for a particular path
    # 
    # ==== Parameters
    # path<String>:: The path of the file to find an engine for
    #---
    # @semipublic
    def engine_for(path)
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
    # ==== Example
    # {{[
    #   Merb::Template.register_extensions(Merb::Template::Erubis, ["erb"])
    # ]}}
    #---
    # @public
    def register_extensions(engine, extensions) 
      raise ArgumentError, "The class you are registering does not have a compile_template method" unless
        engine.respond_to?(:compile_template)
      extensions.each{|ext| EXTENSIONS[ext] = engine }
    end
  end
  
  require 'erubis'
  class Erubis    
    # ==== Parameters
    # path<String>:: A full path to the template
    # name<String>:: The name of the method that will be created
    # mod<Module>:: The module that the compiled method will be placed into
    def self.compile_template(path, name, mod)
      template = ::Erubis::Eruby.new(File.read(path))
      template.def_method(mod, name, path) 
      name     
    end
  
    Merb::Template.register_extensions(self, %w[erb])    
  end
  
end