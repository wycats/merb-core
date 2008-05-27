def sudo
  windows = (PLATFORM =~ /win32|cygwin/) rescue nil
  ENV['MERB_SUDO'] ||= "sudo"
  sudo = windows ? "" : ENV['MERB_SUDO']
end