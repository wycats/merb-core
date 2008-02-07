corelib = File.join(File.dirname(__FILE__), "core_ext")

Dir.glob("#{corelib}/*.rb").each {|fn| require fn}