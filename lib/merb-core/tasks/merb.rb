Dir["#{File.dirname(__FILE__)}/*.rake"].each { |ext| load ext }

# Load any app level custom rakefile extensions
Dir["#{Merb.root}/lib/tasks/**/*.rake"].sort.each { |ext| load ext }
