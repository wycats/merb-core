require 'rubygems'
require 'set'
require 'fileutils'
require 'merb_core/gem_ext/erubis'
require 'merb_core/logger'
require 'merb_core/version'

gem "assistance"
require "assistance"

module Merb
  class << self
    
    attr_accessor :environment, :load_paths
    self.load_paths = Hash.new
		
		# This is the core mechanism for setting up your application layout
		# merb-core won't set a default application layout, but merb-more will
		# use the app/:type layout that is in use in Merb 0.5
		def push_path(type, path, file_glob = "**/*.rb")
		  load_paths[type] = [path, file_glob]
		end
		
		# Application paths
		def root()          @root || Merb::Config[:merb_root] || Dir.pwd  end
		def root=(value)    @root ||= value                               end
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
    self.generator_scope = [:merb_default, :merb, :rspec]
  end

end
