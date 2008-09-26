require File.join(File.dirname(__FILE__), 'gem_management')

module Merb
  module RakeHelper
    
    extend GemManagement
    
    def self.install(name, options = {})
      defaults = { :cache => false }
      defaults[:install_dir] = ENV['GEM_DIR'] if ENV['GEM_DIR']
      opts = defaults.merge(options)
      install_gem_from_src(Dir.pwd, opts)
      ensure_bin_wrapper_for(opts[:install_dir] || Gem.default_dir, Gem.bindir, name)
    end
    
    def self.uninstall(name, options = {})
      defaults = { :ignore => true, :executables => true }
      defaults[:install_dir] = ENV['GEM_DIR'] if ENV['GEM_DIR']
      uninstall_gem(name, defaults.merge(options))
    end
    
  end
end

def sudo
  ENV['MERB_SUDO'] ||= "sudo"
  sudo = windows? ? "" : ENV['MERB_SUDO']
end

def windows?
  (PLATFORM =~ /win32|cygwin/) rescue nil
end

def install_home
  ENV['GEM_HOME'] ? "-i #{ENV['GEM_HOME']}" : ""
end

def install_command(gem_name, gem_version, options = '--no-update-sources --no-rdoc --no-ri')
  options << " -i #{ENV['GEM_DIR']}" if ENV['GEM_DIR']
  %{#{sudo} #{Gem.ruby} -S gem install #{install_home} --local pkg/#{gem_name}-#{gem_version}.gem #{options}}
end

def dev_install_command(gem_name, gem_version, options = '--no-update-sources --no-rdoc --no-ri')
  options << ' --development'
  install_command(gem_name, gem_version, options)
end

def jinstall_command(gem_name, gem_version, options = '--no-update-sources --no-rdoc --no-ri')
  options << " -i #{ENV['GEM_DIR']}" if ENV['GEM_DIR']
  %{#{sudo} jruby -S gem install #{install_home} --local pkg/#{gem_name}-#{gem_version}.gem #{options}}
end

def dev_jinstall_command(gem_name, gem_version, options = '--no-update-sources --no-rdoc --no-ri')
  options << ' --development'
  jinstall_command(gem_name, gem_version, options)
end

def uninstall_command(gem_name, options = '')
  options << " -i #{ENV['GEM_DIR']}" if ENV['GEM_DIR']
  %{#{sudo} #{Gem.ruby} -S gem uninstall #{gem_name} #{options}}
end