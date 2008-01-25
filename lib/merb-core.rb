#---
# require 'merb' must happen after Merb::Config is instantiated

require 'rubygems'
require 'set'
require 'fileutils'
require 'socket'

$LOAD_PATH.push File.dirname(__FILE__) unless 
  $LOAD_PATH.include?(File.dirname(__FILE__)) || 
  $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__)))

require 'merb-core/autoload'
require 'merb-core/core_ext'
require 'merb-core/gem_ext/erubis'
require 'merb-core/logger'
require 'merb-core/version'
require 'merb-core/controller/mime'
require 'merb-core/vendor/facets'

begin
  require "json/ext"
rescue LoadError
  require "json/pure"
end

module Merb
  class << self
    
    def start(argv=ARGV)
      Merb::Config.parse_args(argv)      
      BootLoader.run
      Merb.adapter.start(Merb::Config.to_hash)
    end
    
    attr_accessor :environment, :load_paths, :adapter
    Merb.load_paths = Hash.new { [Merb.root] } unless Merb.load_paths.is_a?(Hash)
      		
		# This is the core mechanism for setting up your application layout
		# merb-core won't set a default application layout, but merb-more will
		# use the app/:type layout that is in use in Merb 0.5
		#
		# ==== Parameters
		# type<Symbol>:: The type of path being registered (i.e. :view)
		# path<String>:: The full path
		# file_glob<String>:: 
		#   A glob that will be used to autoload files under the path
		def push_path(type, path, file_glob = "**/*.rb") enforce!(type => Symbol)
		  load_paths[type] = [path, file_glob]
		end
		
		def dir_for(type)  Merb.load_paths[type].first end
		def glob_for(type) Merb.load_paths[type][1]    end
		
		# Application paths
		def root()          @root || Merb::Config[:merb_root] || Dir.pwd  end
		# ==== Parameters
		# value<String>:: the path to the root of the directory
		def root=(value)    @root = value                                 end
		# ==== Parameters
		# path<String>:: the path to a directory under the root
		def root_path(path) File.join(root, path)                         end
    
		# Logger settings
		attr_accessor :logger
		
		def log_path
		  if $TESTING
        Merb.dir_for(:log) / "merb_test.log"
      elsif !(Merb::Config[:daemonize] || Merb::Config[:cluster] )
        STDOUT
      else
        Merb.dir_for(:log) / "#{Merb::Config[:port]}.log"
		  end
		end
		
		# Framework paths
		def framework_root()  @framework_root ||= File.dirname(__FILE__)  end
		  
		def flat!(&block)
      Merb::Config[:framework] = {}

      Merb::Router.prepare do |r|
        r.default_routes
        block.call(r) if block_given?
      end		  
	  end
		  
    # Set up default variables under Merb
    attr_accessor :generator_scope, :klass_hashes
    Merb.generator_scope = [:merb_default, :merb, :rspec]
    Merb.klass_hashes = []
  end
  
end
