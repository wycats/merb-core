require File.join(File.dirname(__FILE__), 'gem_management')

module Merb
  module RakeHelper
    
    extend GemManagement
    
    def self.install(name, options = {})
      defaults = { :cache => false }
      defaults[:install_dir] = ENV['GEM_DIR'] if ENV['GEM_DIR']
      opts = defaults.merge(options)
      install_gem_from_src(Dir.pwd, opts)
      ensure_wrapper(opts[:install_dir] || Gem.default_dir, name)
    end
    
    def self.install_package(pkg, options = {})
      defaults = { :cache => false }
      defaults[:install_dir] = ENV['GEM_DIR'] if ENV['GEM_DIR']
      opts = defaults.merge(options)
      install_gem(pkg, opts)
      name = File.basename(pkg, '.gem')[/^(.*?)-([\d\.]+)$/, 1]
      ensure_wrapper(opts[:install_dir] || Gem.default_dir, name)
    end
    
    def self.uninstall(name, options = {})
      defaults = { :ignore => true, :executables => true }
      defaults[:install_dir] = ENV['GEM_DIR'] if ENV['GEM_DIR']
      uninstall_gem(name, defaults.merge(options))
    end
    
    def self.sudo
      ENV['MERB_SUDO'] ||= "sudo"
      sudo = windows? ? "" : ENV['MERB_SUDO']
    end

    def self.windows?
      (PLATFORM =~ /win32|cygwin/) rescue nil
    end
    
    protected
    
    def self.ensure_wrapper(gemdir, name)
      # See if there's a local bin dir - one directory up from ./gems
      bindir = File.expand_path(File.join(gemdir, '..', 'bin'))
      # Fall back to system wide bindir - usually needs sudo permissions
      bindir = Gem.bindir unless File.directory?(bindir)
      ensure_bin_wrapper_for(gemdir, bindir, name)
    end
    
  end
end