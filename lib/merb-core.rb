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
require 'merb-core/vendor/facets/inflect'

module Merb
  class << self
    
    def start(argv=ARGV)
      Merb::Config.parse_args(argv)

      if Merb::Config[:init_file]
        require(Merb.root / Merb::Config[:init_file])
      elsif File.exists?(Merb.dir_for(:config) / "merb_init")
        require(Merb.dir_for(:config) / "merb_init")
      elsif File.file?(Merb.dir_for(:application))
        require(Merb.dir_for(:application))
      end
      
      BootLoader.run
      case Merb::Config[:adapter]
      when "mongrel"
        adapter = Merb::Rack::Mongrel
      when "emongrel"
        require 'merb-core/rack/adapter/evented_mongrel'        
        adapter = Merb::Rack::Mongrel
      when "webrick"
        adapter = Merb::Rack::WEBrickengl
      when "fastcgi","fcgi"
        adapter = Merb::Rack::FastCGI
      when "thin"
        adapter = Merb::Rack::Thin
      when "irb"
        adapter = Merb::Rack::Irb        
      else
        adapter = Merb::Rack.const_get(Merb::Config[:adapter].capitalize)
      end    
      adapter.start_server(Merb::Config[:host], Merb::Config[:port].to_i)
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
