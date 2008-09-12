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
  %{#{sudo} gem install #{install_home} --local pkg/#{gem_name}-#{gem_version}.gem #{options}}
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
  %{#{sudo} gem uninstall #{gem_name} #{options}}
end