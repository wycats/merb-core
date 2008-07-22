begin
  require "merb-extlib"
rescue LoadError => e
  puts "Merb-core 0.9.4 and later uses merb-extlib for Ruby core class extensions. Install it from github.com/wycats/merb-extlib."
  exit
end

corelib = File.join(File.dirname(__FILE__), "core_ext")

require corelib/:kernel
