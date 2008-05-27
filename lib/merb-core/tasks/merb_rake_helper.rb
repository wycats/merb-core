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