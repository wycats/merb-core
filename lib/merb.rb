#---
# require 'merb' must happen after Merb::Config is instantiated

require 'rubygems'
require 'set'
require 'fileutils'
require "assistance"

$LOAD_PATH.push File.dirname(__FILE__) unless 
  $LOAD_PATH.include?(File.dirname(__FILE__)) || 
  $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__)))

require 'merb_core/autoload'
require 'merb_core/core_ext'
require 'merb_core/gem_ext/erubis'
require 'merb_core/logger'
require 'merb_core/version'
require 'merb_core/controller/mime'

module Merb
  class << self
    
    def start(argv=ARGV)
      Merb::Config.parse_args(argv)
      BootLoader.run
      
      case Merb::Config[:adapter]
      when "mongrel"
        adapter = Merb::Rack::Mongrel
      when "webrick"
        adapter = Merb::Rack::WEBrick
      when "fastcgi"
        adapter = Merb::Rack::FastCGI
      when "fcgi"
        adapter = Merb::Rack::FastCGI  
      when "thin"
        adapter = Merb::Rack::Thin
      else
        adapter = Merb::Rack.const_get(adapter.capitalize)
      end    
      adapter.start_server(Merb::Config[:host], Merb::Config[:port])
    end
    
    attr_accessor :environment, :load_paths
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
        "#{Merb.root}/log/merb_test.log"
      elsif !(Merb::Config[:daemonize] || Merb::Config[:cluster] )
        STDOUT
      else
        "#{Merb.root}/log/merb.#{Merb::Config[:port]}.log"
		  end
		end
		
		# Framework paths
		def framework_root()  @framework_root ||= File.dirname(__FILE__)          end
		  
    # Set up default generator scope
    attr_accessor :generator_scope
    Merb.generator_scope = [:merb_default, :merb, :rspec]
  end

end
