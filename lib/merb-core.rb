#---
# require 'merb' must happen after Merb::Config is instantiated
require 'rubygems'
require 'set'
require 'fileutils'
require 'socket'

$LOAD_PATH.unshift File.dirname(__FILE__) unless
  $LOAD_PATH.include?(File.dirname(__FILE__)) ||
  $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__)))

module Merb
  module GlobalHelpers; end
  class << self

    # Startup Merb by setting up the Config and starting the server.
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
      Merb::Server.start(Merb::Config[:port], Merb::Config[:cluster])
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

    attr_accessor :environment, :load_paths, :adapter
    
    alias :env :environment
    
    Merb.load_paths = Hash.new { [Merb.root] } unless Merb.load_paths.is_a?(Hash)

    # This is the core mechanism for setting up your application layout
    # merb-core won't set a default application layout, but merb-more will
    # use the app/:type layout that is in use in Merb 0.5.
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

    def remove_paths(*args)
      args.each {|arg| load_paths.delete(arg)}
    end

    # ==== Parameters
    # type<Symbol>:: The type of path to retrieve directory for, e.g. :view.
    #
    # ==== Returns
    # String:: The directory for the requested type.
    def dir_for(type)  Merb.load_paths[type].first end

    # ==== Parameters
    # type<Symbol>:: The type of path to retrieve glob for, e.g. :view.
    #
    # ===== Returns
    # String:: The pattern with which to match files within the type directory.
    def glob_for(type) Merb.load_paths[type][1]    end

    # ==== Returns
    # String:: The Merb root path.
    def root()          @root || Merb::Config[:merb_root] || Dir.pwd  end

    # ==== Parameters
    # value<String>:: Path to the root directory.
    def root=(value)    @root = value                                 end

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
    def root_path(*path) File.join(root, *path)                       end

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
    # String:: The directory that contains the log file.
    def log_path
      case Merb::Config[:log_file]
      when String then File.dirname(Merb::Config[:log_file])
      else Merb.root_path("log")
      end
    end

    # ==== Returns
    # String:: The root directory of the Merb framework.
    def framework_root()  @framework_root ||= File.dirname(__FILE__)  end

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
    attr_accessor :generator_scope, :klass_hashes
    Merb.generator_scope = [:merb_default, :merb, :rspec]
    Merb.klass_hashes = []

    attr_reader :registered_session_types

    # ==== Parameters
    # name<~to_s>:: Name of the session type to register.
    # file<String>:: The file that defines this session type.
    # description<String>:: An optional description of the session type.
    def register_session_type(name, file, description = nil)
      @registered_session_types ||= Dictionary.new
      @registered_session_types[name] = {
        :file => file,
        :description => (description || "Using #{name} sessions")
      }
    end

    attr_accessor :frozen

    # ==== Returns
    # Boolean:: True if Merb is running via script/frozen-merb or other freezer.
    def frozen?
      @frozen
    end

    # Used by script/frozen-merb and other freezers to mark Merb as frozen.
    def frozen!
      @frozen = true
    end
    
    # Load configuration and assign logger.
    #
    # ==== Parameters
    # options<Hash>:: Options to pass on to the Merb config.
    def load_config(options = {})
      Merb::Config.setup({ :log_file => STDOUT, :log_level => :warn, :log_auto_flush => true }.merge(options))
      Merb::BootLoader::Logger.run
    end
    
    # Load all basic dependencies (selected BootLoaders only).
    #
    # ==== Parameters
    # options<Hash>:: Options to pass on to the Merb config.
    def load_dependencies(options = {})
      load_config(options)
      Merb::BootLoader::BuildFramework.run
      Merb::BootLoader::Dependencies.run
      Merb::BootLoader::BeforeAppRuns.run
    end
    
    # Reload the framework.
    def reload
      Merb::BootLoader::ReloadClasses.reload
    end
    
    # ==== Returns
    # Boolean:: True if Merb is running via spec_helper.rb or other TEST scenario.
    def testing?
      $TESTING || Merb::Config[:testing]
    end

    # If block was given configures using the block.
    #
    # ==== Parameters
    # &block:: Configuration parameter block, see example below.
    #
    # ==== Returns
    # Hash:: The current configuration.
    #
    # ==== Examples
    #   Merb.config do
    #     beer               "good"
    #     hashish            :foo => "bar"
    #     environment        "development"
    #     log_level          "debug"
    #     use_mutex          false
    #     session_store      "cookie"
    #     session_secret_key "0d05a226affa226623eb18700"
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
      disabled_components.push *components
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
    # Array:: All Rakefiles for plugins.
    def rakefiles
      @rakefiles ||= ['merb-core/test/tasks/spectasks']
    end

    # ==== Parameters
    # *rakefiles:: Rakefiles to add to the list of plugin Rakefiles.
    def add_rakefiles(*rakefiles)
      @rakefiles ||= ['merb-core/test/tasks/spectasks']
      @rakefiles += rakefiles
    end
  end
end

require 'merb-core/autoload'
require 'merb-core/server'
require 'merb-core/gem_ext/erubis'
require 'merb-core/logger'
require 'merb-core/version'
require 'merb-core/controller/mime'
require 'merb-core/vendor/facets'

# Set the environment if it hasn't already been set.
Merb.environment ||= ENV['MERB_ENV'] || Merb::Config[:environment] || (Merb.testing? ? 'test' : 'development')