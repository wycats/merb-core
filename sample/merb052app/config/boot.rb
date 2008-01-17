frozen_framework_path = File.join(File.dirname(__FILE__), "..", "framework")

unless defined?(Merb::framework_root)
  if File.directory?(frozen_framework_path)
    $:.unshift frozen_framework_path
    require File.join(frozen_framework_path, "merb")
  else  
    require 'rubygems' # required for test_unit loading
    require 'merb'
  end
end
