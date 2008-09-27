require 'merb-core/tasks/merb_rake_helper'
Dir[File.dirname(__FILE__) / '*.rake'].each { |ext| load ext }