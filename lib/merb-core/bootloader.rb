module Merb

  class BootLoader

    # def self.subclasses
    #---
    # @semipublic
    cattr_accessor :subclasses, :after_load_callbacks, :before_load_callbacks, :finished
    self.subclasses, self.after_load_callbacks, self.before_load_callbacks, self.finished = [], [], [], []

    class << self

      # Adds the inheriting class to the list of subclasses in a position
      # specified by the before and after methods.
      #
      # ==== Parameters
      # klass<Class>:: The class inheriting from Merb::BootLoader.
      def inherited(klass)
        subclasses << klass.to_s
        super
      end

      # ==== Parameters
      # klass<~to_s>::
      #   The boot loader class after which this boot loader should be run.
      #
      #---
      # @public
      def after(klass)
        move_klass(klass, 1)
      end

      # ==== Parameters
      # klass<~to_s>::
      #   The boot loader class before which this boot loader should be run.
      #
      #---
      # @public
      def before(klass)
        move_klass(klass, 0)
      end

      # Move a class that is inside the bootloader to some place in the Array,
      # relative to another class.
      #
      # ==== Parameters
      # klass<~to_s>::
      #   The klass to move the bootloader relative to
      # where<Integer>::
      #   0 means insert it before; 1 means insert it after
      def move_klass(klass, where)
        index = Merb::BootLoader.subclasses.index(klass.to_s)
        if index
          Merb::BootLoader.subclasses.delete(self.to_s)
          Merb::BootLoader.subclasses.insert(index + where, self.to_s)
        end
      end

      # Runs all boot loader classes by calling their run methods.
      def run
        Merb.started = true
        subklasses = subclasses.dup
        until subclasses.empty?
          time = Time.now.to_i
          bootloader = subclasses.shift
          if (ENV['DEBUG'] || $DEBUG || Merb::Config[:verbose]) && Merb.logger
            Merb.logger.debug!("Loading: #{bootloader}")
          end
          Object.full_const_get(bootloader).run
          if (ENV['DEBUG'] || $DEBUG || Merb::Config[:verbose]) && Merb.logger
            Merb.logger.debug!("It took: #{Time.now.to_i - time}")
          end
          self.finished << bootloader
        end
        self.subclasses = subklasses
      end
      
      # Determines whether or not a specific bootloader has finished yet.
      #
      # ==== Parameters
      # bootloader<String, Class>:: The name of the bootloader to check.
      #
      # ==== Returns
      # Boolean:: Whether or not the bootloader has finished.
      def finished?(bootloader)
        self.finished.include?(bootloader.to_s)
      end

      # Set up the default framework
      #
      # ==== Returns
      # nil
      #
      #---
      # @public
      def default_framework
        %w[view model helper controller mailer part].each do |component|
          Merb.push_path(component.to_sym, Merb.root_path("app/#{component}s"))
        end
        Merb.push_path(:application,  Merb.root_path("app" / "controllers" / "application.rb"))
        Merb.push_path(:config,       Merb.root_path("config"), nil)
        Merb.push_path(:router,       Merb.dir_for(:config), (Merb::Config[:router_file] || "router.rb"))
        Merb.push_path(:lib,          Merb.root_path("lib"), nil)
        Merb.push_path(:log,          Merb.log_path, nil)
        Merb.push_path(:public,       Merb.root_path("public"), nil)
        Merb.push_path(:stylesheet,   Merb.dir_for(:public) / "stylesheets", nil)
        Merb.push_path(:javascript,   Merb.dir_for(:public) / "javascripts", nil)
        Merb.push_path(:image,        Merb.dir_for(:public) / "images", nil)
        nil
      end

      # ==== Parameters
      # &block::
      #   A block to be added to the callbacks that will be executed after the
      #   app loads.
      #
      #---
      # @public
      def after_app_loads(&block)
        after_load_callbacks << block
      end

      # ==== Parameters
      # &block::
      #   A block to be added to the callbacks that will be executed before the
      #   app loads.
      #
      #---
      # @public
      def before_app_loads(&block)
        before_load_callbacks << block
      end
    end

  end

end

# Set up the logger.
#
# Place the logger inside of the Merb log directory (set up in
# Merb::BootLoader::BuildFramework)
class Merb::BootLoader::Logger < Merb::BootLoader

  # Sets Merb.logger to a new logger created based on the config settings.
  def self.run
    Merb.logger = Merb::Logger.new(Merb.log_file, Merb::Config[:log_level], Merb::Config[:log_delimiter], Merb::Config[:log_auto_flush])
    print_warnings
  end
  
  def self.print_warnings
    if Gem::Version.new(Gem::RubyGemsVersion) < Gem::Version.new("1.1")
      Merb.logger.warn! "Merb requires Rubygems 1.1 and later. Please upgrade RubyGems with gem update --system."
    end
  end
end

# Stores pid file.
#
# Only run if daemonization or clustering options specified on start.
# Port is taken from Merb::Config and must be already set at this point.
class Merb::BootLoader::DropPidFile <  Merb::BootLoader
  class << self

    # Stores a PID file if Merb is running daemonized or clustered.
    def run
      Merb::Server.store_pid(Merb::Config[:port]) if Merb::Config[:daemonize] || Merb::Config[:cluster]
    end
  end
end

# Setup some useful defaults
class Merb::BootLoader::Defaults < Merb::BootLoader
  def self.run
    Merb::Request.http_method_overrides.concat([
      proc { |c| c.params[:_method] },
      proc { |c| c.env['HTTP_X_HTTP_METHOD_OVERRIDE'] }
    ])
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
# To override the default, set Merb::Config[:framework] in your initialization
# file. Merb::Config[:framework] takes a Hash whose key is the name of the
# path, and whose values can be passed into Merb.push_path (see Merb.push_path
# for full details).
#
# ==== Notes
# All paths will default to Merb.root, so you can get a flat-file structure by
# doing Merb::Config[:framework] = {}.
#
# ==== Example
#   Merb::Config[:framework] = {
#     :view   => Merb.root / "views",
#     :model  => Merb.root / "models",
#     :lib    => Merb.root / "lib",
#     :public => [Merb.root / "public", nil]
#     :router => [Merb.root / "config", "router.rb"]
#   }
#
# That will set up a flat directory structure with the config files and
# controller files under Merb.root, but with models, views, and lib with their
# own folders off of Merb.root.
class Merb::BootLoader::BuildFramework < Merb::BootLoader
  class << self

    # Builds the framework directory structure.
    def run
      build_framework
    end

    # This method should be overridden in init.rb before Merb.start to set up
    # a different framework structure.
    def build_framework
      if File.exists?(Merb.root / "config" / "framework.rb")
        require Merb.root / "config" / "framework"
      elsif File.exists?(Merb.root / "framework.rb")
        require Merb.root / "framework"
      else
        Merb::BootLoader.default_framework
      end
      (Merb::Config[:framework] || {}).each do |name, path|
        path = Array(path)
        Merb.push_path(name, path.first, path.length == 2 ? path[1] : "**/*.rb")
      end
    end
  end
end

class Merb::BootLoader::Dependencies < Merb::BootLoader

  cattr_accessor :dependencies
  self.dependencies = []

  # Load the init_file specified in Merb::Config or if not specified, the
  # init.rb file from the Merb configuration directory, and any environment
  # files, which register the list of necessary dependencies and any
  # after_app_loads hooks.
  #
  # Dependencies can hook into the bootloader process itself by using
  # before or after insertion methods. Since these are loaded from this
  # bootloader (Dependencies), they can only adapt the bootloaders that
  # haven't been loaded up until this point.

  def self.run
    load_initfile
    load_env_config
    enable_json_gem unless Merb::disabled?(:json)
    load_dependencies
    update_logger
  end

  def self.load_dependencies
    dependencies.each { |name, ver| Kernel.load_dependency(name, *ver) }
  end

  def self.enable_json_gem
    require "json/ext"
  rescue LoadError
    require "json/pure"
  end

  def self.update_logger
    updated_logger_options = [ Merb.log_file, Merb::Config[:log_level], Merb::Config[:log_delimiter], Merb::Config[:log_auto_flush] ]
    Merb::BootLoader::Logger.run if updated_logger_options != Merb.logger.init_args
  end

  private

    # Determines the path for the environment configuration file
    def self.env_config
      Merb.dir_for(:config) / "environments" / (Merb.environment + ".rb")
    end

    # Checks to see whether or not an environment configuration exists
    def self.env_config?
      Merb.environment && File.exist?(env_config)
    end

    # Loads the environment configuration file, if any
    def self.load_env_config
      load(env_config) if env_config?
    end

    # Determines the init file to use, if any.
    # By default Merb uses init.rb from application config directory.
    def self.initfile
      if Merb::Config[:init_file]
        Merb::Config[:init_file].chomp(".rb") + ".rb"
      else
        Merb.dir_for(:config) / "init.rb"
      end
    end

    # Loads the init file, should one exist
    def self.load_initfile
      load(initfile) if File.exists?(initfile)
    end

end

class Merb::BootLoader::MixinSession < Merb::BootLoader

  # Mixin the session functionality; this is done before BeforeAppLoads
  # so that SessionContainer and SessionStoreContainer can be subclassed by
  # plugin session stores for example - these need to be loaded in a
  # before_app_loads block or a BootLoader that runs after MixinSession.
  #
  # Note: access to Merb::Config is needed, so it needs to run after 
  # Merb::BootLoader::Dependencies is done.
  def self.run
    require 'merb-core/dispatch/session'
    Merb::Controller.send(:include, ::Merb::SessionMixin)
    Merb::Request.send(:include, ::Merb::SessionMixin::RequestMixin)
  end

end

class Merb::BootLoader::BeforeAppLoads < Merb::BootLoader

  # Call any before_app_loads hooks that were registered via before_app_loads
  # in any plugins.
  def self.run
    Merb::BootLoader.before_load_callbacks.each { |x| x.call }
  end
end

# Load all classes inside the load paths.
#
# This is used in conjunction with Merb::BootLoader::ReloadClasses to track
# files that need to be reloaded, and which constants need to be removed in
# order to reload a file.
#
# This also adds the model, controller, and lib directories to the load path,
# so they can be required in order to avoid load-order issues.
class Merb::BootLoader::LoadClasses < Merb::BootLoader
  LOADED_CLASSES = {}
  MTIMES = {}

  class << self

    # Load all classes from Merb's native load paths.
    def run
      # Add models, controllers, helpers and lib to the load path
      $LOAD_PATH.unshift Merb.dir_for(:model)
      $LOAD_PATH.unshift Merb.dir_for(:controller)
      $LOAD_PATH.unshift Merb.dir_for(:lib)
      $LOAD_PATH.unshift Merb.dir_for(:helper)

      # Load application file if it exists - for flat applications
      load_file Merb.dir_for(:application) if File.file?(Merb.dir_for(:application))
      
      # Load classes and their requirements
      Merb.load_paths.each do |component, path|
        next unless path.last && component != :application
        load_classes(path.first / path.last)
      end

      Merb::Controller.send :include, Merb::GlobalHelpers
    end
    
    # ==== Parameters
    # file<String>:: The file to load.
    def load_file(file)
      klasses = ObjectSpace.classes.dup
      load file
      LOADED_CLASSES[file] = ObjectSpace.classes - klasses
      MTIMES[file] = File.mtime(file)
    end
    
    # Load classes from given paths - using path/glob pattern.
    #
    # *paths<Array>::
    #   Array of paths to load classes from - may contain glob pattern
    def load_classes(*paths)
      orphaned_classes = []
      paths.flatten.each do |path|
        Dir[path].each do |file|
          begin
            load_file file
          rescue NameError => ne
            orphaned_classes.unshift(file)
          end
        end
      end
      load_classes_with_requirements(orphaned_classes)
    end

    # ==== Parameters
    # file<String>:: The file to reload.
    def reload(file)
      remove_classes_in_file(file) { |f| load_file(f) }
    end
    
    # Reload the router to regenerate all routes.
    def reload_router!
      if File.file?(router_file = Merb.dir_for(:router) / Merb.glob_for(:router))
        Merb::Router.reset!
        reload router_file
      end
    end
    
    # ==== Parameters
    # file<String>:: The file to remove classes for.
    # &block:: A block to call with the file that has been removed.
    def remove_classes_in_file(file, &block)
      Merb.klass_hashes.each {|x| x.protect_keys!}
      if klasses = LOADED_CLASSES.delete(file)
        klasses.each { |klass| remove_constant(klass) unless klass.to_s =~ /Router/ }
      end
      yield file if block_given?
      Merb.klass_hashes.each {|x| x.unprotect_keys!}
    end

    # ==== Parameters
    # const<Class>:: The class to remove.
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
      object = parts[-1].to_s
      begin
        base.send(:remove_const, object)
        Merb.logger.debug("Removed constant #{object} from #{base}")
      rescue NameError
        Merb.logger.debug("Failed to remove constant #{object} from #{base}")
      end
    end
    
    private

    # "Better loading" of classes.  If a class fails to load due to a NameError
    # it will be added to the failed_classes and load cycle will be repeated unless
    # no classes load.
    #
    # ==== Parameters
    # klasses<Array[Class]>:: Classes to load.
    def load_classes_with_requirements(klasses)
      klasses.uniq!

      while klasses.size > 0
        # Note size to make sure things are loading
        size_at_start = klasses.size

        # List of failed classes
        failed_classes = []
        # Map classes to exceptions
        error_map = {}

        klasses.each do |klass|
          klasses.delete(klass)
          begin
            load_file klass
          rescue NameError => ne
            error_map[klass] = ne
            failed_classes.push(klass)
          end
        end

        # Keep list of classes unique
        failed_classes.each { |k| klasses.push(k) unless klasses.include?(k) }

        # Stop processing if nothing loads or if everything has loaded
        if klasses.size == size_at_start && klasses.size != 0
          # Write all remaining failed classes and their exceptions to the log
          error_map.only(*failed_classes).each do |klass, e|
            Merb.logger.fatal! "Could not load #{klass}:\n\n#{e.message} - (#{e.class})\n\n#{(e.backtrace || []).join("\n")}"
          end
          raise LoadError, "Could not load #{failed_classes.inspect} (see log for details)."
        end
        break if(klasses.size == size_at_start || klasses.size == 0)
      end
    end

  end

end

class Merb::BootLoader::Templates < Merb::BootLoader
  class << self

    # Loads the templates into the Merb::InlineTemplates module.
    def run
      template_paths.each do |path|
        Merb::Template.inline_template(File.open(path))
      end
    end

    # ==== Returns
    # Array[String]:: Template files found.
    def template_paths
      extension_glob = "{#{Merb::Template.template_extensions.join(',')}}"

      # This gets all templates set in the controllers template roots
      # We separate the two maps because most of controllers will have
      # the same _template_root, so it's silly to be globbing the same
      # path over and over.
      controller_view_paths = []
      Merb::AbstractController._abstract_subclasses.each do |klass|
        next if (const = Object.full_const_get(klass))._template_root.blank?
        controller_view_paths += const._template_roots.map { |pair| pair.first }
      end
      template_paths = controller_view_paths.uniq.compact.map { |path| Dir["#{path}/**/*.#{extension_glob}"] }

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
# :xml:: to_xml, application/xml or text/xml or application/x-xml
# :js:: to_json, text/javascript ot application/javascript or application/x-javascript
# :json:: to_json, application/json or text/x-json
class Merb::BootLoader::MimeTypes < Merb::BootLoader

  # Registers the default MIME types.
  def self.run
    Merb.add_mime_type(:all,  nil,      %w[*/*])
    Merb.add_mime_type(:yaml, :to_yaml, %w[application/x-yaml text/yaml], :charset => "utf-8")
    Merb.add_mime_type(:text, :to_text, %w[text/plain], :charset => "utf-8")
    Merb.add_mime_type(:html, :to_html, %w[text/html application/xhtml+xml application/html], :charset => "utf-8")
    Merb.add_mime_type(:xml,  :to_xml,  %w[application/xml text/xml application/x-xml], {:charset => "utf-8"}, 0.9998)
    Merb.add_mime_type(:js,   :to_json, %w[text/javascript application/javascript application/x-javascript], :charset => "utf-8")
    Merb.add_mime_type(:json, :to_json, %w[application/json text/x-json], :charset => "utf-8")
  end
end

class Merb::BootLoader::Cookies < Merb::BootLoader
  
  def self.run
    require 'merb-core/dispatch/cookies'
    Merb::Controller.send(:include, Merb::CookiesMixin)
    Merb::Request.send(:include, Merb::CookiesMixin::RequestMixin)
  end
  
end

class Merb::BootLoader::SetupSession < Merb::BootLoader

  # Enable the configured session container(s); any class that inherits from
  # SessionContainer will be considered by its session_store_type attribute.
  def self.run
    # Require all standard session containers.
    Dir[Merb.framework_root / "merb-core" / "dispatch" / "session" / "*.rb"].each do |file|
      base_name = File.basename(file, ".rb")
      require file unless base_name == "container" || base_name == "store_container"
    end
    
    # Set some defaults.
    Merb::Config[:session_id_key] ||= "_session_id"
    
    # List of all session_stores from :session_stores and :session_store config options.
    config_stores = Merb::Config.session_stores
    
    # Register all configured session stores - any loaded session container class
    # (subclassed from Merb::SessionContainer) will be available for registration.
    Merb::SessionContainer.subclasses.each do |class_name|
      if(store = Object.full_const_get(class_name)) && 
        config_stores.include?(store.session_store_type)
          Merb::Request.register_session_type(store.session_store_type, class_name)
      end
    end
    
    # Mixin the Merb::Session module to add app-level functionality to sessions
    Merb::SessionContainer.send(:include, Merb::Session)
  end

end

class Merb::BootLoader::AfterAppLoads < Merb::BootLoader

  # Call any after_app_loads hooks that were registered via after_app_loads in
  # init.rb.
  def self.run
    Merb::BootLoader.after_load_callbacks.each {|x| x.call }
  end
end

# In case someone's running a sparse app, the default exceptions require the
# Exceptions class.
class Merb::BootLoader::SetupStubClasses < Merb::BootLoader
  def self.run
    unless defined?(Exceptions)
      Object.class_eval <<-RUBY
        class Application < Merb::Controller
        end

        class Exceptions < Application
        end
      RUBY
    end
  end
end

class Merb::BootLoader::ChooseAdapter < Merb::BootLoader

  # Choose the Rack adapter/server to use and set Merb.adapter.
  def self.run
    Merb.adapter = Merb::Rack::Adapter.get(Merb::Config[:adapter])
  end
end

class Merb::BootLoader::StartWorkerThread < Merb::BootLoader

  # Choose the Rack adapter/server to use and set Merb.adapter.
  def self.run
    Merb::Worker.new
  end
end

class Merb::BootLoader::RackUpApplication < Merb::BootLoader
  # Setup the Merb Rack App or read a rackup file located at
  # Merb::Config[:rackup] with the same syntax as the
  # rackup tool that comes with rack. Automatically evals the file in
  # the context of a Rack::Builder.new { } block. Allows for mounting
  # additional apps or middleware.
  def self.run
    require 'rack'
    if File.exists?(Merb.dir_for(:config) / "rack.rb")
      Merb::Config[:rackup] ||= Merb.dir_for(:config) / "rack.rb"
    end

    if Merb::Config[:rackup]
      rackup_code = File.read(Merb::Config[:rackup])
      Merb::Config[:app] = eval("::Rack::Builder.new {( #{rackup_code}\n )}.to_app", TOPLEVEL_BINDING, Merb::Config[:rackup])
    else
      Merb::Config[:app] = ::Rack::Builder.new {
         if prefix = ::Merb::Config[:path_prefix]
           use Merb::Rack::PathPrefix, prefix
         end
         use Merb::Rack::Static, Merb.dir_for(:public)
         run Merb::Rack::Application.new
       }.to_app
    end
    
  end
end

class Merb::BootLoader::ReloadClasses < Merb::BootLoader

  class TimedExecutor
    def self.every(seconds, &block)
      Thread.abort_on_exception = true
      Thread.new do
        loop do
          sleep( seconds )
          block.call
        end
        Thread.exit
      end
    end
  end

  # Setup the class reloader if it's been specified in config.
  def self.run
    return unless Merb::Config[:reload_classes]

    TimedExecutor.every(Merb::Config[:reload_time] || 0.5) do
      reload
    end
    
  end

  # Reloads all files.
  def self.reload
    paths = []
    Merb.load_paths.each do |path_name, file_info|
      path, glob = file_info
      next unless glob
      paths << Dir[path / glob]
    end

    paths << Merb.dir_for(:application) if Merb.dir_for(:application) && File.file?(Merb.dir_for(:application))

    paths.flatten.each do |file|
      next if Merb::BootLoader::LoadClasses::MTIMES[file] && Merb::BootLoader::LoadClasses::MTIMES[file] == File.mtime(file)
      Merb::BootLoader::LoadClasses.reload(file)
    end
  end
end

class Merb::BootLoader::ReloadTemplates < Merb::BootLoader

  # Reloads all templates if the reload_templates key has been set in config.
  def self.run
    unless Merb::Config.key?(:reload_templates)
      Merb::Config[:reload_templates] = (Merb.environment == "development")
    end
  end
end