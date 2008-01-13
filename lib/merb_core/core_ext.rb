corelib = File.join(File.dirname(__FILE__), "core_ext")

Dir.glob("#{corelib}/*").each {|fn| require(File.join(fn))}