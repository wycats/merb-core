module Merb
  
  class BootLoader
    
    cattr_accessor :subclasses, :after_load_callbacks
    self.subclasses = []
    self.after_load_callbacks = []
    class_inheritable_accessor :_after, :_before
    
    class << self
      def inherited(klass)
        if !klass._before && !klass._after
          subclasses << klass.to_s
        elsif klass._before && subclasses.index(klass._before)
          subclasses.insert(subclasses.index(klass._before), klass.to_s)
        elsif klass._after && subclasses.index(klass._after)
          subclasses.insert(subclasses.index(klass._after) + 1, klass.to_s)
        end
        super
      end
      
      def run
        subklasses = subclasses.dup
        Object.full_const_get(subclasses.shift).run until subclasses.empty?
        subclasses = subklasses
      end
      
      def after(klass)
        self._after = klass.to_s
      end
      
      def before(klass)
        self._before = klass.to_s
      end
      
      def after_app_loads(&block)
        after_load_callbacks << block
      end
    end
    
  end
  
end

# At this point, the config from the command-line will have been parsed, but 
# the init-file will not have.

# Load the correct environment.
# 
# Set Merb.environment to Merb::Config[:environment], which is set by the -e
# command-line flag. 
class Merb::BootLoader::Environment < Merb::BootLoader
  def self.run
    Merb.environment = Merb::Config[:environment]
  end
end

# Load the init-file.
# 
# The file will be searched for in the following order:
# * A relative path provided via a -I command line switch
# * merb_init.rb, relative to the root
# * merb_init.rb, relative to the config directory
# * application.rb, relative to the root
class Merb::BootLoader::InitFile < Merb::BootLoader
  def self.run
    if Merb::Config[:init_file] && File.exists?(Merb.root / Merb::Config[:init_file])
      require(Merb.root / Merb::Config[:init_file])
    elsif File.exists?(Merb.root / "merb_init.rb")
      require(Merb.root / "merb_init")
    elsif File.exists?(Merb.root / "config" / "merb_init.rb")
      require(Merb.root / "config" / "merb_init")  
    elsif File.file?(Merb.root / "application.rb")
      require(Merb.root / "application")
    end
  end
end

# Build the framework paths.
#
# By default, the following paths will be used:
# application:: Merb.root/app/controller/application.rb
# config:: Merb.root/config
# lib:: Merb.root/lib
# log:: Merb.root/log
# view:: Merb.root/app/views
# model:: Merb.root/app/models
# controller:: Merb.root/app/controllers
# helper:: Merb.root/app/helpers
# mailer:: Merb.root/app/mailers
# part:: Merb.root/app/parts
#
# To override the default, set Merb::Config[:framework] in your initialization file.
# Merb::Config[:framework] takes a Hash whose key is the name of the path, and whose
# values can be passed into Merb.push_path (see Merb.push_path for full details).
#
# ==== Note
# All paths will default to Merb.root, so you can get a flat-file structure by doing
# Merb::Config[:framework] = {}
# 
# ==== Example
# {{[
#   Merb::Config[:framework] = {
#     :view => Merb.root / "views"
#     :model => Merb.root / "models"
#     :lib => Merb.root / "lib"
#   }
# ]}}
# 
# That will set up a flat directory structure with the config files and controller files
# under Merb.root, but with models, views, and lib with their own folders off of Merb.root.
class Merb::BootLoader::BuildFramework < Merb::BootLoader
  class << self
    def run
      build_framework
    end
  
    # This method should be overridden in merb_init.rb before Merb.start to set up a different
    # framework structure
    def build_framework
      unless Merb::Config[:framework]
        %w[view model controller helper mailer part].each do |component|
          Merb.push_path(component.to_sym, Merb.root_path("app/#{component}s"))
        end
        Merb.push_path(:application,    Merb.root_path("app/controllers/application.rb"))
        Merb.push_path(:config,         Merb.root_path("config"), "*.rb")
        Merb.push_path(:lib,            Merb.root_path("lib"), nil)
        Merb.push_path(:log,            Merb.root_path("log"), nil)
      else
        Merb::Config[:framework].each do |name, path|
          Merb.push_path(name, Merb.root_path(path.first), path[1])
        end
      end
    end
  end
end

# Load the dependencies file, which registers the list of necessary dependencies and
# an after_
class Merb::BootLoader::Dependencies < Merb::BootLoader
  def self.run
    if File.exists?(Merb.dir_for(:config) / "dependencies.rb")
      require Merb.dir_for(:config) / "dependencies"
    end
  end
end

# Set up the logger.
#
# Place the logger inside of the Merb log directory (set up in
# Merb::BootLoader::BuildFramework)
class Merb::BootLoader::Logger < Merb::BootLoader
  def self.run
    FileUtils.mkdir Merb.dir_for(:log) unless File.directory?(Merb.dir_for(:log))
    Merb.logger = Merb::Logger.new(Merb.log_path)
    Merb.logger.level = Merb::Logger.const_get(Merb::Config[:log_level].upcase) rescue Merb::Logger::INFO    
  end
end

# Load the router.
#
# This will attempt to load router.rb from the Merb configuration directory (set up in
# Merb::BootLoader::BuildFramework)
class Merb::BootLoader::LoadRouter < Merb::BootLoader
  def self.run
    require(Merb.dir_for(:config) / "router") if File.exists?(Merb.dir_for(:config) / "router")
  end
end

# Load all classes inside the load paths.
#
# This is used in conjunction with Merb::BootLoader::ReloadClasses to track files that
# need to be reloaded, and which constants need to be removed in order to reload a file.
#
# This also adds the model, controller, and lib directories to the load path, so they
# can be required in order to avoid load-order issues.
class Merb::BootLoader::LoadClasses < Merb::BootLoader
  LOADED_CLASSES = {}
  MTIMES = {}
  
  class << self
    def run
      # Add models, controllers, and lib to the load path
      $LOAD_PATH.unshift Merb.dir_for(:model)      
      $LOAD_PATH.unshift Merb.dir_for(:controller)
      $LOAD_PATH.unshift Merb.dir_for(:lib)        
    
      # Require all the files in the registered load paths
      Merb.load_paths.each do |name, path|
        next unless path.last
        Dir[path.first / path.last].each do |file|
          load_file file
        end
      end
    end

    def load_file(file)
      klasses = ObjectSpace.classes.dup
      load file
      LOADED_CLASSES[file] = ObjectSpace.classes - klasses
      MTIMES[file] = File.mtime(file)      
    end

    def reload(file)
      Merb.klass_hashes.each {|x| x.protect_keys!}
      if klasses = LOADED_CLASSES.delete(file)
        klasses.each { |klass| remove_constant(klass) }
      end
      load_file file
      Merb.klass_hashes.each {|x| x.unprotect_keys!}      
    end
  
    def remove_constant(const)
      # This is to support superclasses (like AbstractController) that track
      # their subclasses in a class variable. Classes that wish to use this
      # functionality are required to alias it to _subclasses_list. Plugins
      # for ORMs and other libraries should keep this in mind.
      
      superklass = const
      until (superklass = superklass.superclass).nil?
        if superklass.respond_to?(:_subclasses_list)
          superklass.send(:_subclasses_list).delete(klass)
          superklass.send(:_subclasses_list).delete(klass.to_s)          
        end
      end
  
      parts = const.to_s.split("::")
      base = parts.size == 1 ? Object : Object.full_const_get(parts[0..-2].join("::"))
      object = parts[-1].intern
      Merb.logger.debug("Removing constant #{object} from #{base}")
      base.send(:remove_const, object) if object
    end
  end
  
end

# Loads the templates into the Merb::InlineTemplates module.
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

# Register the default MIME types:
#
# By default, the mime-types include:
# :all:: no transform, */*
# :yaml:: to_yaml, application/x-yaml or text/yaml
# :text:: to_text, text/plain
# :html:: to_html, text/html or application/xhtml+xml or application/html
# :xml:: to_xml, application/xml or text/xml or application/x-xml, adds "Encoding: UTF-8" response header
# :js:: to_json, text/javascript ot application/javascript or application/x-javascript
# :json:: to_json, application/json or text/x-json
class Merb::BootLoader::MimeTypes < Merb::BootLoader
  def self.run
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

# Call any after_app_loads hooks that were registered via after_app_loads in dependencies.rb.
class Merb::BootLoader::AfterAppLoads < Merb::BootLoader
  def self.run
    Merb::BootLoader.after_load_callbacks.each {|x| x.call }
  end
end

# Choose the Rack adapter/server to use and set Merb.adapter
class Merb::BootLoader::MixinSessionContainer < Merb::BootLoader
  def self.run
    Merb.register_session_type('memory',
      Merb.framework_root / "merb-core" / "dispatch" / "session" / "memory",
      "Using in-memory sessions; sessions will be lost whenever the server stops.")

    Merb.register_session_type('cookie', # Last session type becomes the default
      Merb.framework_root /  "merb-core" / "dispatch" / "session" / "cookie",
      "Using 'share-nothing' cookie sessions (4kb limit per client)")

    Merb::Controller.class_eval do
      lib = File.join(Merb.framework_root, 'merb')
      session_store = Merb::Config[:session_store].to_s
      if ["", "false", "none"].include?(session_store)
        Merb.logger.info "Not Using Sessions"
      elsif reg = Merb.registered_session_types[session_store]
        if session_store == "cookie" 
          Merb::BootLoader::MixinSessionContainer.check_for_secret_key
        end
        require reg[:file]
        include ::Merb::SessionMixin
        Merb.logger.info reg[:description]
      else
        Merb.logger.info "Session store not found, '#{Merb::Config[:session_store]}'."
        Merb.logger.info "Defaulting to CookieStore Sessions"
        Merb::BootLoader::MixinSessionContainer.check_for_secret_key
        require Merb.registered_session_types['cookie'][:file]
        include ::Merb::SessionMixin
        Merb.logger.info "(plugin not installed?)"
      end
    end
    
    Merb.logger.flush  
  end
  
  
  def self.check_for_secret_key
    unless Merb::Config[:session_secret_key] && (Merb::Config[:session_secret_key].length >= 16)
      Merb.logger.info("You must specify a session_secret_key in your merb.yml, and it must be at least 16 characters\nbailing out...")
      exit! 
    end            
    Merb::Controller._session_secret_key = Merb::Config[:session_secret_key]
  end
end

# Choose the Rack adapter/server to use and set Merb.adapter
class Merb::BootLoader::ChooseAdapter < Merb::BootLoader
  def self.run
    Merb.adapter = Merb::Rack::Adapter.get(Merb::Config[:adapter])
  end
end

# Setup the Merb Rack App or read a rack.rb config file located at the Merb.root 
# or Merb.root / config / rack.rb with the same syntax as the rackup tool that 
# comes with rack. Automatically evals the rack.rb file in the context of a
# Rack::Builder.new { } block. Allows for mounting additional apps or middleware
class Merb::BootLoader::RackUpApplication < Merb::BootLoader
  def self.run
    if File.exists?(Merb.root / "rack.rb")
      Merb::Config[:app] =  eval("Rack::Builder.new {( #{IO.read(Merb.root / 'rack')}\n )}.to_app")
    elsif File.exists?(Merb.root / "config" / "rack.rb")
      Merb::Config[:app] =  eval("Rack::Builder.new {( #{IO.read(Merb.root / 'config' / 'rack')}\n )}.to_app") 
    else
      Merb::Config[:app] = ::Merb::Rack::Application.new
    end
  end
end

# Setup the class reloader.
class Merb::BootLoader::ReloadClasses < Merb::BootLoader
  def self.run
    return unless Merb::Config[:reload_classes]
    
    Thread.abort_on_exception = true
    Thread.new do
      loop do
        sleep( Merb::Config[:reload_time] || 0.5 )
        reload
      end
      Thread.exit
    end
  end
  
  def self.reload
    paths = []
    Merb.load_paths.each do |path_name, file_info|
      path, glob = file_info
      next unless glob
      paths << Dir[path / glob]
    end
    
    paths.flatten.each do |file|
      next if Merb::BootLoader::LoadClasses::MTIMES[file] && Merb::BootLoader::LoadClasses::MTIMES[file] == File.mtime(file)      
      Merb::BootLoader::LoadClasses.reload(file)
    end    
  end
end