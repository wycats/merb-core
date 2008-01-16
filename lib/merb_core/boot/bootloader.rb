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
        subclasses.each {|klass| Object.full_const_get(klass).run }
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

class Merb::BootLoader::LoadInit < Merb::BootLoader
  def self.run
    if Merb::Config[:init_file]
      require Merb.root / Merb::Config[:init_file]
    elsif File.exists?(Merb.root / "config" / "merb_init.rb")
      require Merb.root / "config" / "merb_init"
    elsif File.exists?(Merb.root / "merb_init.rb")
      require Merb.root / "merb_init"
    elsif File.exists?(Merb.root / "application.rb")
      require Merb.root / "application"
    end
  end
end

class Merb::BootLoader::Environment < Merb::BootLoader
  def self.run
    Merb.environment = Merb::Config[:environment]
  end
end

class Merb::BootLoader::Logger < Merb::BootLoader
  def self.run
    Merb.logger = Merb::Logger.new(Merb.dir_for(:log) / "test_log")
    Merb.logger.level = Merb::Logger.const_get(Merb::Config[:log_level].upcase) rescue Merb::Logger::INFO    
  end
end

class Merb::BootLoader::BuildFramework < Merb::BootLoader
  class << self
    def run
      build_framework
    end
  
    # This method should be overridden in merb_init.rb before Merb.start to set up a different
    # framework structure
    def build_framework
      %w[view model controller helper mailer part].each do |component|
        Merb.push_path(component.to_sym, Merb.root_path("app/#{component}s"))
      end
      Merb.push_path(:application,    Merb.root_path("app/controllers/application.rb"))
      Merb.push_path(:config,         Merb.root_path("config/router.rb"))
      Merb.push_path(:lib,            Merb.root_path("lib"))    
    end
  end
end

class Merb::BootLoader::LoadPaths < Merb::BootLoader
  LOADED_CLASSES = {}
  
  class << self
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
          require file
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
  
end

class Merb::BootLoader::Templates < Merb::BootLoader
  class << self
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
      end.uniq.compact.map {|path| Dir["#{path}/**/*.#{extension_glob}"] }
    
      # This gets the templates that might be created outside controllers
      # template roots.  eg app/views/shared/*
      template_paths << Dir["#{Merb.dir_for(:view)}/**/*.#{extension_glob}"] if Merb.dir_for(:view)
    
      template_paths.flatten.compact.uniq
    end
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

  def self.run
    @@libraries.each do |exclude, choices|
      require_first_working(*choices) unless Merb::Config[exclude]
    end
  end

  def self.require_first_working(first, *rest)
    p first, rest
    require first
  rescue LoadError
    raise LoadError if rest.empty?
    require_first_working rest.unshift, *rest
  end
end

class Merb::BootLoader::MimeTypes < Merb::BootLoader
  def self.run
    # Sets the default mime-types
    # 
    # By default, the mime-types include:
    # :all:: no transform, */*
    # :yaml:: to_yaml, application/x-yaml or text/yaml
    # :text:: to_text, text/plain
    # :html:: to_html, text/html or application/xhtml+xml or application/html
    # :xml:: to_xml, application/xml or text/xml or application/x-xml, adds "Encoding: UTF-8" response header
    # :js:: to_json, text/javascript ot application/javascript or application/x-javascript
    # :json:: to_json, application/json or text/x-json
    Merb.available_mime_types.clear
    Merb.add_mime_type(:all,  nil,      %w[*/*])
    Merb.add_mime_type(:yaml, :to_yaml, %w[application/x-yaml text/yaml])
    Merb.add_mime_type(:text, :to_text, %w[text/plain])
    Merb.add_mime_type(:html, :to_html, %w[text/html application/xhtml+xml application/html])
    Merb.add_mime_type(:xml,  :to_xml,  %w[application/xml text/xml application/x-xml], :Encoding => "UTF-8")
    Merb.add_mime_type(:js,   :to_json, %w[text/javascript application/javascript application/x-javascript])
    Merb.add_mime_type(:json, :to_json, %w[application/json text/x-json])      
  end
end