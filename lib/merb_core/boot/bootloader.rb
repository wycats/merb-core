module Merb
  
  class BootLoader
    
    cattr_accessor :subclasses
    self.subclasses = []
    class_inheritable_accessor :_after, :_before
    
    class << self
      
      def inherited(klass)
        if !klass._before && !klass._after
          subclasses << klass.to_s
        elsif klass._before
          subclasses.insert(subclasses.index(klass._before), klass.to_s)
        else
          subclasses.insert(subclasses.index(klass._before) + 1, klass.to_s)          
        end
        super
      end
      
      def run
        subclasses.each {|klass| Object.full_const_get(klass).new.run }
      end
      
      def after(klass)
        self._after = klass.to_s
      end
      
      def before(klass)
        self._before = klass.to_s
      end
      
    end
    
  end
  
end

class Merb::BootLoader::BuildFramework < Merb::BootLoader
  def run
    build_framework
  end
  
  # This method should be overridden in merb_init.rb before Merb.start to set up a different
  # framework structure
  def build_framework
    %[view model controller helper mailer part].each do |component|
      Merb.push_path(component.to_sym, Merb.root_path("app/#{component}s"))
    end
    Merb.push_path(:app_controller, Merb.root_path("app/controllers/application.rb"))
    Merb.push_path(:config,         Merb.root_path("config/router.rb"))
    Merb.push_path(:lib,            Merb.root_path("lib"))    
  end
end

class Merb::BootLoader::LoadPaths < Merb::BootLoader
  LOADED_CLASSES = {}
  
  def run
    # Add models, controllers, and lib to the load path
    $LOAD_PATH.unshift Merb.load_paths[:model].first      if Merb.load_paths[:model]
    $LOAD_PATH.unshift Merb.load_paths[:controller].first if Merb.load_paths[:controller]
    $LOAD_PATH.unshift Merb.load_paths[:lib].first        if Merb.load_paths[:lib]
    
    # Require all the files in the registered load paths
    puts Merb.load_paths.inspect
    Merb.load_paths.each do |name, path|
      Dir[path.first / path.last].each do |file| 
        klasses = ObjectSpace.classes.dup
        require f
        LOADED_CLASSES[file] = ObjectSpace.classes - klasses
      end
    end
  end

  def reload(file)
    if klasses = LOADED_CLASSES[file]
      klasses.each do |klass|
        remove_constant(klass)
      end
    end
    load file
  end
  
  def remove_constant(const)
    # This is to support superclasses (like AbstractController) that track
    # their subclasses in a class variable. Classes that wish to use this
    # functionality are required to alias it to _subclasses_list. Plugins
    # for ORMs and other libraries should keep this in mind.
    if klass.superclass.respond_to?(:_subclasses_list)
      klass.superclass.send(:_subclasses_list).delete(klass)
      klass.superclass.send(:_subclasses_list).delete(klass.to_s)          
    end
  
    parts = const.to_s.split("::")
    base = parts.size == 1 ? Object : Object.full_const_get(parts[0..-2].join("::"))
    object = parts[-1].intern
    Merb.logger.debugger("Removing constant #{object} from #{base}")
    base.send(:remove_const, object) if object
  end
  
end

class Merb::BootLoader::Templates < Merb::BootLoader
  def run
    template_paths.each do |path|
      Merb::Template.inline_template(path)
    end
  end
  
  def template_paths
    extension_glob = "{#{Merb::Template::EXTENSIONS.keys.join(',')}}"

    # This gets all templates set in the controllers template roots        
    # We separate the two maps because most of controllers will have
    # the same _template_root, so it's silly to be globbing the same
    # path over and over.
    template_paths = Merb::AbstractController._abstract_subclasses.map do |klass| 
      Object.full_const_get(klass)._template_root
    end.uniq.map {|path| Dir["#{path}/**/*.#{extension_glob}"] }
    
    # This gets the templates that might be created outside controllers
    # template roots.  eg app/views/shared/*
    template_paths << Dir["#{Merb.load_paths[:view]}/**/*.#{extension_glob}"] if Merb.load_paths[:view]
    
    template_paths.flatten.compact.uniq
  end  
end

class Merb::BootLoader::Libraries < Merb::BootLoader
  @@libraries = {:disable_json_gem => %w[json/ext json/pure]}

  # Add other libraries to load in early in the boot process
  # 
  # ==== Parameters
  # hsh<Hash[exclude, tries]>:: A hash or libraries to add
  #
  # ==== Hash
  # exclude<Symbol>:: 
  #   Exclude this library if Merb::Config[exclude] is true
  # tries<Array[String]>::
  #   Try to require each item in the Array in succesion. If the item is not found,
  #   try the next one. If none of the items are found, raise a LoadError.
  def self.add_libraries(hsh)
    @@libraries.merge!(hsh)
  end
  
  def run
    @@libraries.each do |exclude, choices|
      require_first_working(*choices) unless Merb::Config[exclude]
    end
  end
  
  def require_first_working(first, *rest)
    p first, rest
    require first
  rescue LoadError
    raise LoadError if rest.empty?
    require_first_working rest.unshift, *rest
  end
end