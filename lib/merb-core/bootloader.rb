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
        until subclasses.empty?
          bootloader = subclasses.shift
          puts "Loading: #{bootloader}" if ENV['DEBUG']
          Object.full_const_get(bootloader).run
        end  
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
  
    # This method should be overridden in init.rb before Merb.start to set up a different
    # framework structure
    def build_framework
      unless Merb::Config[:framework]
        %w[view model controller helper mailer part].each do |component|
          Merb.push_path(component.to_sym, Merb.root_path("app/#{component}s"))
        end
        Merb.push_path(:application,  Merb.root_path("app/controllers/application.rb"))
        Merb.push_path(:config,       Merb.root_path("config"), nil)
        Merb.push_path(:environments, Merb.dir_for(:config) / "environments", nil)
        Merb.push_path(:lib,          Merb.root_path("lib"), nil)
        Merb.push_path(:log,          Merb.log_path, nil)
        Merb.push_path(:public,       Merb.root_path("public"), nil)
        Merb.push_path(:stylesheet,   Merb.dir_for(:public) / "stylesheets", nil)
        Merb.push_path(:javascript,   Merb.dir_for(:public) / "javascripts", nil)
        Merb.push_path(:image,        Merb.dir_for(:public) / "images", nil)        
      else
        Merb::Config[:framework].each do |name, path|
          Merb.push_path(name, Merb.root_path(path.first), path[1])
        end
      end
    end
  end
end

# Set up the logger.
#
# Place the logger inside of the Merb log directory (set up in
# Merb::BootLoader::BuildFramework)
class Merb::BootLoader::Logger < Merb::BootLoader
  
  def self.run
    Merb.logger = Merb::Logger.new(Merb.log_file, Merb::Config[:log_level])
  end
end

class Merb::BootLoader::DropPidFile <  Merb::BootLoader
  class << self
    
    def run
      Merb::Server.store_pid(Merb::Config[:port])
    end
  end
end

# Load the init_file specified in Merb::Config or if not specified, the init.rb file
# from the Merb configuration directory, and any environment files, which register the
# list of necessary dependencies and any after_app_loads hooks.
class Merb::BootLoader::Dependencies < Merb::BootLoader
  
  def self.run
    if Merb::Config[:init_file]
      initfile = Merb::Config[:init_file].chomp(".rb")
    else
      initfile = Merb.dir_for(:config) / "init"
    end
    require initfile if File.exists?(initfile + ".rb")

    if !Merb.environment.nil? && File.exist?(Merb.dir_for(:environments) / (Merb.environment + ".rb"))
      require Merb.dir_for(:environments) / Merb.environment
    end
  end
end

# Load the router.
#
# This will attempt to load router.rb from the Merb configuration directory (set up in
# Merb::BootLoader::BuildFramework)
class Merb::BootLoader::LoadRouter < Merb::BootLoader
  
  def self.run
    require(Merb.dir_for(:config) / "router") if File.exists?(Merb.dir_for(:config) / "router.rb")
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
    
      load_file Merb.dir_for(:application) if File.exists?(Merb.dir_for(:application))
    
      # Require all the files in the registered load paths
      Merb.load_paths.each do |name, path|
        next unless path.last && name != :application
        Dir[path.first / path.last].each do |file|
          load_file file
        end
      end
      Merb::Controller.send :include, Merb::GlobalHelpers
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

# Mixin the correct session container.
class Merb::BootLoader::MixinSessionContainer < Merb::BootLoader

  def self.run
    Merb.register_session_type('memory',
      Merb.framework_root / "merb-core" / "dispatch" / "session" / "memory",
      "Using in-memory sessions; sessions will be lost whenever the server stops.")

    Merb.register_session_type('cookie', # Last session type becomes the default
      Merb.framework_root /  "merb-core" / "dispatch" / "session" / "cookie",
      "Using 'share-nothing' cookie sessions (4kb limit per client)")

    Merb::Controller.class_eval do
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
# DOC
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
    if File.exists?(Merb.dir_for(:config) / "rack.rb")
      Merb::Config[:app] =  eval("::Rack::Builder.new {( #{IO.read(Merb.dir_for(:config) / 'rack.rb')}\n )}.to_app", TOPLEVEL_BINDING)
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

class Merb::BootLoader::ReloadTemplates < Merb::BootLoader
  def self.run
    unless Merb::Config.key?(:reload_templates)
      Merb::Config[:reload_templates] = (Merb.environment == "development")
    end
  end
end