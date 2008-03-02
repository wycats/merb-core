require 'open3'

# Runs specs in all files matching the file pattern.
#
# ==== Parameters
# globs<String, Array[String]>:: File patterns to look for.
# spec_cmd<~to_s>:: The spec command. Defaults to "spec".
def run_specs(globs, spec_cmd='spec')
  require "optparse"
  require "spec"
  globs = globs.is_a?(Array) ? globs : [globs]
  examples, failures, errors, pending = 0, 0, 0, 0
  globs.each do |glob|
    Dir[glob].each do |spec|
      response = Open3.popen3("#{spec_cmd} #{File.expand_path(spec)} -f s -c") do |i,o,e|
        while out = o.gets
          STDOUT.puts out
          STDOUT.flush
          if out =~ /\d+ example/
            e, f, p = out.match(/(\d+) examples?, (\d+) failures?(?:, (\d+) pending?)?/)[1..-1]
            examples += e.to_i; failures += f.to_i; pending += p.to_i          
          end
        end
        errors += 1 if e.is_a?(IO)
        STDOUT.puts e.read if e.is_a?(IO)
      end
    end
  end
  puts
  puts "*** TOTALS ***"
  if failures == 0
    print "\e[32m"
  else
    print "\e[31m"
  end
  puts "#{examples} examples, #{failures} failures, #{errors} errors, #{pending} pending"
  print "\e[0m"  
end
