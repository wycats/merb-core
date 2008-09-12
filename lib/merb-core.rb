#---
# require 'merb' must happen after Merb::Config is instantiated
require 'rubygems'
require 'set'
require 'fileutils'
require 'socket'
require 'pathname'
require "extlib"

__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless
  $LOAD_PATH.include?(__DIR__) ||
  $LOAD_PATH.include?(File.expand_path(__DIR__))

require 'merb-core' / 'vendor' / 'facets'

module Merb
  # Create stub module for global controller helpers.
  module GlobalHelpers; end
  
  class << self

    # Merge environment settings
    # Can allow you to have a "localdev" that runs like your "development"
    #   OR
    # A "staging" environment that runs like your "production"
    #
    # ==== Examples
    # From any environment config file (ie, development.rb, custom.rb, localdev.rb, etc)
    #   staging.rb:
    #     Merb.merge_env "production"         #We want to use all the settings production uses
    #     Merb::Config.use { |c|
    #       c[:log_level]         = "debug"   #except we want debug log level
    #       c[:exception_details] = true      #and we want to see exception details
    #     }
    #
    # ==== Parameters
    # env<~String>:: Environment to run like
    # use_db<~Boolean>:: Should Merb use the merged environments DB connection
    #     Defaults to +false+
    def merge_env(env,use_db=false)
      if Merb.environment_info.nil?
        Merb.environment_info = {
          :real_env => Merb.environment,
          :merged_envs => [],
          :db_env => Merb.environment
        }
      end
      
      #Only load if it hasn't been loaded
      unless Merb.environment_info[:merged_envs].member? env
        Merb.environment_info[:merged_envs] << env
        
        env_file = Merb.dir_for(:config) / "environments" / ("#{env}.rb")
        if File.exists?(env_file)
          load(env_file)
        else
          Merb.logger.warn! "Environment file does not exist! #{env_file}"
        end
        
      end
      
      # Mark specific environment to load when ORM loads,
      # if multiple environments are loaded, the last one
      # with use_db as TRUE will be loaded
      if use_db
        Merb.environment_info[:db_env] = env
      end
    end


    # Startup Merb by setting up the Config and starting the server.
    # This is where Merb application environment and root path are set.
    #
    # ==== Parameters
    # argv<String, Hash>::
    #   The config arguments to start Merb with. Defaults to +ARGV+.
    def start(argv=ARGV)
      if Hash === argv
        Merb::Config.setup(argv)
      else
        Merb::Config.parse_args(argv)
      end
      Merb.environment = Merb::Config[:environment]
      Merb.root = Merb::Config[:merb_root]
      case Merb::Config[:action]
      when :kill
        Merb::Server.kill(Merb::Config[:port], 1)
      when :kill_9
        Merb::Server.kill(Merb::Config[:port], 9)
      else
        Merb::Server.start(Merb::Config[:port], Merb::Config[:cluster])
      end
    end

    # Start the Merb environment, but only if it hasn't been loaded yet.
    #
    # ==== Parameters
    # argv<String, Hash>::
    #   The config arguments to start Merb with. Defaults to +ARGV+.
    def start_environment(argv=ARGV)
      unless (@started ||= false)
        start(argv)
        @started = true
      end
    end

    # Restart the Merb environment explicitly.
    #
    # ==== Parameters
    # argv<String, Hash>::
    #   The config arguments to restart Merb with. Defaults to +Merb::Config+.
    def restart_environment(argv={})
      @started = false
      start_environment(Merb::Config.to_hash.merge(argv))
    end

    attr_accessor :environment, :load_paths, :adapter, :environment_info, :started

    alias :env :environment
    alias :started? :started

    Merb.load_paths = Dictionary.new { [Merb.root] } unless Merb.load_paths.is_a?(Dictionary)

    # This is the core mechanism for setting up your application layout.
    # There are three application layouts in Merb:
    #
    # Regular app/:type layout of Ruby on Rails fame:
    #
    # app/models      for models
    # app/mailers     for mailers (special type of controllers)
    # app/parts       for parts, Merb components
    # app/views       for templates
    # app/controllers for controller
    # lib             for libraries
    #
    # Flat application layout:
    #
    # application.rb       for models, controllers, mailers, etc
    # config/init.rb       for initialization and router configuration
    # config/framework.rb  for framework and dependencies configuration
    # views                for views
    #
    # and Camping-style "very flat" application layout, where the whole Merb
    # application and configs fit into a single file.
    #
    # ==== Notes
    # Autoloading for lib uses empty glob by default. If you
    # want to have your libraries under lib use autoload, add
    # the following to Merb init file:
    #
    # Merb.push_path(:lib, Merb.root / "lib", "**/*.rb") # glob set explicity.
    #
    # Then lib/magicwand/lib/magicwand.rb with MagicWand module will
    # be autoloaded when you first access that constant.
    #
    # ==== Examples
    # This method gives you a way to build up your own application
    # structure, for instance, to reflect the structure Rails
    # uses to simplify transition of legacy application, you can
    # set it up like this:
    #
    # Merb.push_path(:model,      Merb.root / "app" / "models",      "**/*.rb")
    # Merb.push_path(:mailer,     Merb.root / "app" / "models",      "**/*.rb")
    # Merb.push_path(:controller, Merb.root / "app" / "controllers", "**/*.rb")
    # Merb.push_path(:view,       Merb.root / "app" / "views",       "**/*.rb")
    #
    # ==== Parameters
    # type<Symbol>:: The type of path being registered (i.e. :view)
    # path<String>:: The full path
    # file_glob<String>::
    #   A glob that will be used to autoload files under the path. Defaults to
    #   "**/*.rb".
    def push_path(type, path, file_glob = "**/*.rb")
      enforce!(type => Symbol)
      load_paths[type] = [path, file_glob]
    end

    # Removes given types of application components
    # from load path Merb uses for autoloading.
    #
    # ==== Parameters
    # *args<Array(Symbol)>::
    #   components names, for instance, :views, :models
    #
    # ==== Examples
    # Using this combined with Merb::GlobalHelpers.push_path
    # you can make your Merb application use legacy Rails
    # application components.
    #
    # Merb.root = "path/to/legacy/app/root"
    # Merb.remove_paths(:mailer)
    # Merb.push_path(:mailer,     Merb.root / "app" / "models",      "**/*.rb")
    #
    # Will make Merb use app/models for mailers just like Ruby on Rails does.
    def remove_paths(*args)
      args.each {|arg| load_paths.delete(arg)}
    end

    # ==== Parameters
    # type<Symbol>:: The type of path to retrieve directory for, e.g. :view.
    #
    # ==== Returns
    # String:: The directory for the requested type.
    def dir_for(type)
      Merb.load_paths[type].first
    end

    # ==== Parameters
    # type<Symbol>:: The type of path to retrieve glob for, e.g. :view.
    #
    # ===== Returns
    # String:: The pattern with which to match files within the type directory.
    def glob_for(type)
      Merb.load_paths[type][1]
    end

    # ==== Returns
    # String:: The Merb root path.
    def root
      @root || Merb::Config[:merb_root] || File.expand_path(Dir.pwd)
    end

    # ==== Parameters
    # value<String>:: Path to the root directory.
    def root=(value)
      @root = value
    end

    # ==== Parameters
    # *path::
    #   The relative path (or list of path components) to a directory under the
    #   root of the application.
    #
    # ==== Returns
    # String:: The full path including the root.
    #
    # ==== Examples
    #   Merb.root = "/home/merb/app"
    #   Merb.path("images") # => "/home/merb/app/images"
    #   Merb.path("views", "admin") # => "/home/merb/app/views/admin"
    #---
    # @public
    def root_path(*path)
      File.join(root, *path)
    end

    # Logger settings
    attr_accessor :logger

    # ==== Returns
    # String::
    #   The path to the log file. If this Merb instance is running as a daemon
    #   this will return +STDOUT+.
    def log_file
      if Merb::Config[:log_file]
        Merb::Config[:log_file]
      elsif Merb.testing?
        log_path / "merb_test.log"
      elsif !(Merb::Config[:daemonize] || Merb::Config[:cluster])
        STDOUT
      else
        log_path / "merb.#{Merb::Config[:port]}.log"
      end
    end

    # ==== Returns
    # String:: Path to directory that contains the log file.
    def log_path
      case Merb::Config[:log_file]
      when String then File.dirname(Merb::Config[:log_file])
      else Merb.root_path("log")
      end
    end

    # ==== Returns
    # String:: The path of root directory of the Merb framework.
    def framework_root
      @framework_root ||= File.dirname(__FILE__)
    end

    # ==== Returns
    # RegExp::
    #   Regular expression against which deferred actions
    #   are matched by Rack application handler.
    #
    # ==== Notes
    # Concatenates :deferred_actions configuration option
    # values.
    def deferred_actions
      @deferred ||= begin
        if Merb::Config[:deferred_actions].empty?
          /^\0$/
        else
          /#{Merb::Config[:deferred_actions].join("|")}/
        end
      end
    end

    # Allows flat apps by setting no default framework directories and yielding
    # a Merb::Router instance. This is optional since the router will
    # automatically configure the app with default routes.
    #
    # ==== Block parameters
    # r<Merb::Router::Behavior>::
    #   The root behavior upon which new routes can be added.
    def flat!(framework = {})
      Merb::Config[:framework] = framework

      Merb::Router.prepare do |r|
        yield(r) if block_given?
        r.default_routes
      end
    end

    # Set up default variables under Merb
    attr_accessor :klass_hashes, :orm, :test_framework, :template_engine

    # Returns the default ORM for this application. For instance, :datamapper.
    #
    # ==== Returns
    # <Symbol>:: default ORM.
    def orm
      @orm ||= :none
    end
    
    # @deprecated
    def orm_generator_scope
      Merb.logger.warn!("WARNING: Merb.orm_generator_scope is deprecated")
      return :merb_default if Merb.orm == :none
      Merb.orm
    end

    # Returns the default test framework for this application. For instance :rspec.
    #
    # ==== Returns
    # <Symbol>:: default test framework.
    def test_framework
      @test_framework ||= :rspec
    end
    
    # @deprecated
    def test_framework_generator_scope
      Merb.logger.warn!("WARNING: Merb.test_framework_generator_scope is deprecated")
      Merb.test_framework
    end
    
    # Returns the default template engine for this application. For instance :haml.
    #
    # ==== Returns
    # <Symbol>:: default template engine.
    def template_engine
      @template_engine ||= :erb
    end

    Merb.klass_hashes = []

    attr_accessor :frozen

    # ==== Returns
    # Boolean:: True if Merb is running as an application with bundled gems.
    # Can only be disabled by --no-bundle option on startup (or for Rakefile
    # use NO_BUNDLE=true to disable local gems).
    #
    # ==== Notes
    # Bundling required gems makes your application independent from the 
    # environment it runs in. This is a good practice to freeze application 
    # framework and gems it uses and very useful when application is run in 
    # some sort of sandbox, for instance, shared hosting with preconfigured gems.
    def bundled?
      ENV.key?("BUNDLE") || Merb::Config[:bundle] || ENV.key?("NO_BUNDLE")
    end

    # Load configuration and assign logger.
    #
    # ==== Parameters
    # options<Hash>:: Options to pass on to the Merb config.
    #
    # ==== Options
    # :host<String>::             host to bind to,
    #                             default is 0.0.0.0.
    #
    # :port<Fixnum>::             port to run Merb application on,
    #                             default is 4000.
    #
    # :adapter<String>::          name of Rack adapter to use,
    #                             default is "runner"
    #
    # :rackup<String>::           name of Rack init file to use,
    #                             default is "rack.rb"
    #
    # :reload_classes<Boolean>::  whether Merb should reload
    #                             classes on each request,
    #                             default is true
    #
    # :environment<String>::      name of environment to use,
    #                             default is development
    #
    # :merb_root<String>::        Merb application root,
    #                             default is Dir.pwd
    #
    # :use_mutex<Boolean>::       turns action dispatch synchronization
    #                             on or off, default is on (true)
    #
    # :log_delimiter<String>::    what Merb logger uses as delimiter
    #                             between message sections, default is " ~ "
    #
    # :log_auto_flush<Boolean>::  whether the log should automatically
    #                             flush after new messages are
    #                             added, defaults to true.
    #
    # :log_file<IO>::             IO for logger. Default is STDOUT.
    #
    # :log_level<Symbol>::        logger level, default is :warn
    #
    # :disabled_components<Array[Symbol]>::
    #   array of disabled component names,
    #   for instance, to disable json gem,
    #   specify :json. Default is empty array.
    #
    # :deferred_actions<Array(Symbol, String)]>::
    #   names of actions that should be deferred
    #   no matter what controller they belong to.
    #   Default is empty array.
    #
    # Some of these options come from command line on Merb
    # application start, some of them are set in Merb init file
    # or environment-specific.
    def load_config(options = {})
      Merb::Config.setup({ :log_file => STDOUT, :log_level => :warn, :log_auto_flush => true }.merge(options))
      Merb::BootLoader::Logger.run
    end

    # Load all basic dependencies (selected BootLoaders only).
    # This sets up Merb framework component paths
    # (directories for models, controllers, etc) using
    # framework.rb or default layout, loads init file
    # and dependencies specified in it and runs before_app_loads hooks.
    #
    # ==== Parameters
    # options<Hash>:: Options to pass on to the Merb config.
    def load_dependencies(options = {})
      load_config(options)
      Merb::BootLoader::BuildFramework.run
      Merb::BootLoader::Dependencies.run
      Merb::BootLoader::BeforeAppLoads.run
    end

    # Reload application and framework classes.
    # See Merb::BootLoader::ReloadClasses for details.
    def reload
      Merb::BootLoader::ReloadClasses.reload
    end

    # ==== Returns
    # Boolean:: True if Merb environment is testing for instance,
    # Merb is running with RSpec, Test::Unit of other testing facility.
    def testing?
      $TESTING || Merb::Config[:testing]
    end

    # Ask the question about which environment you're in.
    # ==== Parameters
    # env<Symbol, String>:: Name of the environment to query
    #
    # ==== Examples
    # Merb.env #=> production
    # Merb.env?(:production) #=> true
    # Merb.env?(:development) #=> false
    def env?(env)
      Merb.env == env.to_s
    end

    # If block was given configures using the block.
    #
    # ==== Parameters
    # &block:: Configuration parameter block, see example below.
    #
    # ==== Returns
    # Hash:: The current configuration.
    #
    # ==== Notes
    # See Merb::GlobalHelpers.load_config for configuration
    # options list.
    #
    # ==== Examples
    #   Merb.config do
    #     beer               "good"
    #     hashish            :foo => "bar"
    #     environment        "development"
    #     log_level          "debug"
    #     use_mutex          false
    #     exception_details  true
    #     reload_classes     true
    #     reload_time        0.5
    #   end
    def config(&block)
      Merb::Config.configure(&block) if block_given?
      Config
    end

    # Disables the given core components, like a Gem for example.
    #
    # ==== Parameters
    # *args:: One or more symbols of Merb internal components.
    def disable(*components)
      disabled_components.push(*components)
    end

    # ==== Parameters
    # Array:: All components that should be disabled.
    def disabled_components=(components)
      disabled_components.replace components
    end

    # ==== Returns
    # Array:: All components that have been disabled.
    def disabled_components
      Merb::Config[:disabled_components] ||= []
    end

    # ==== Returns
    # Boolean:: True if all components (or just one) are disabled.
    def disabled?(*components)
      components.all? { |c| disabled_components.include?(c) }
    end

    # ==== Returns
    # Array(String):: Paths Rakefiles are loaded from.
    #
    # ==== Notes
    # Recommended way to find out what paths Rakefiles
    # are loaded from.
    def rakefiles
      @rakefiles ||= ['merb-core/test/tasks/spectasks']
    end
    
    # === Returns
    # Array(String):: Paths generators are loaded from
    #
    # === Notes
    # Recommended way to find out what paths generators
    # are loaded from.
    def generators
      @generators ||= []
    end

    # ==== Parameters
    # *rakefiles:: Rakefile pathss to add to the list of Rakefiles.
    #
    # ==== Notes
    # Recommended way to add Rakefiles load path for plugins authors.
    def add_rakefiles(*rakefiles)
      @rakefiles ||= ['merb-core/test/tasks/spectasks']
      @rakefiles += rakefiles
    end
    
    # ==== Parameters
    # *generators:: Generator paths to add to the list of generators.
    #
    # ==== Notes
    # Recommended way to add Generator load paths for plugin authors.
    def add_generators(*generators)
      @generators ||= []
      @generators += generators
    end

  end
end

require 'merb-core/autoload'
require 'merb-core/server'
require 'merb-core/gem_ext/erubis'
require 'merb-core/logger'
require 'merb-core/version'
require 'merb-core/controller/mime'

# Set the environment if it hasn't already been set.
Merb.environment ||= ENV['MERB_ENV'] || Merb::Config[:environment] || (Merb.testing? ? 'test' : 'development')
