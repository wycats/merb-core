$x = 1

def requirable?(*filenames)
  files = {}
  results = {}
  filenames.each do |name|
    pid = fork do
      begin
        require filename
        exit!(0)
      rescue Exception => e
        exit!(1)
      end
    end
    files[pid] = name
  end
  codes = Process.waitall
  codes.each do |pid, code|
    results[files[pid]] = code
  end
  results
end

# puts requirable?("#{File.dirname(__FILE__)}/rollback2")

require "rubygems"
require "rbench"

# GC.disable

FILES = ["#{File.dirname(__FILE__)}/rollback2"] * 200

RBench.run(3) do
  report("stuff") do
    requirable?(*FILES)
  end
end