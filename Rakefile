require "rake"
require "rake/clean"
require "rake/gempackagetask"
require "rake/rdoctask"
require "rake/testtask"
require "spec/rake/spectask"
require "fileutils"

def __DIR__
  File.dirname(__FILE__)
end

require __DIR__ + "/tools/rakehelp"
require __DIR__ + "/tools/annotation_extract"

include FileUtils

NAME = "merb-core"

require "lib/merb-core/version"
require "lib/merb-core/test/run_specs"

##############################################################################
# Packaging & Installation
##############################################################################
CLEAN.include ["**/.*.sw?", "pkg", "lib/*.bundle", "*.gem", "doc/rdoc", ".config", "coverage", "cache"]

windows = (PLATFORM =~ /win32|cygwin/) rescue nil

SUDO = windows ? "" : "sudo"

desc "Packages up Merb."
task :default => :package

task :merb => [:clean, :rdoc, :package]

spec = Gem::Specification.new do |s|
  s.name         = NAME
  s.version      = Merb::VERSION
  s.platform     = Gem::Platform::RUBY
  s.author       = "Ezra Zygmuntowicz"
  s.email        = "ez@engineyard.com"
  s.homepage     = "http://merb.devjavu.com"
  s.summary      = "Merb. Pocket rocket web framework."
  s.bindir       = "bin"
  s.description  = s.summary
  s.executables  = %w( merb )
  s.require_path = "lib"
  s.files        = %w( LICENSE README Rakefile TODO ) + Dir["{docs,bin,spec,lib,examples,app_generators,merb_generators,merb_default_generators,rspec_generators,test_unit_generators,script}/**/*"]

  # rdoc
  s.has_rdoc         = true
  s.extra_rdoc_files = %w( README LICENSE TODO )
  #s.rdoc_options     += RDOC_OPTS + ["--exclude", "^(app|uploads)"]

  # Dependencies
  s.add_dependency "erubis"
  s.add_dependency "rake"
  s.add_dependency "json_pure"
  s.add_dependency "rspec"
  s.add_dependency "rack"
  s.add_dependency "hpricot"
  s.add_dependency "mime-types"
  # Requirements
  s.requirements << "install the json gem to get faster json parsing"
  s.required_ruby_version = ">= 1.8.4"
end

Rake::GemPackageTask.new(spec) do |package|
  package.gem_spec = spec
end

desc "Run :package and install the resulting .gem"
task :install => :package do
  sh %{#{SUDO} gem install --local pkg/#{NAME}-#{Merb::VERSION}.gem --no-rdoc --no-ri}
end

desc "Run :package and install the resulting .gem with jruby"
task :jinstall => :package do
  sh %{#{SUDO} jruby -S gem install pkg/#{NAME}-#{Merb::VERSION}.gem --no-rdoc --no-ri}
end

desc "Run :clean and uninstall the .gem"
task :uninstall => :clean do
  sh %{#{SUDO} gem uninstall #{NAME}}
end

##############################################################################
# Documentation
##############################################################################
task :doc => [:rdoc]
namespace :doc do

  Rake::RDocTask.new do |rdoc|
    files = ["README", "LICENSE", "CHANGELOG", "lib/**/*.rb"]
    rdoc.rdoc_files.add(files)
    rdoc.main = "README"
    rdoc.title = "Merb Docs"
    rdoc.template = __DIR__ + "/tools/allison-2.0.2/lib/allison.rb"
    rdoc.rdoc_dir = "doc/rdoc"
    rdoc.options << "--line-numbers" << "--inline-source"
  end

  desc "run webgen"
  task :webgen do
    sh %{cd doc/site; webgen}
  end

  desc "rdoc to rubyforge"
  task :rubyforge do
    # sh %{rake doc}
    sh %{#{SUDO} chmod -R 755 doc} unless windows
    sh %{/usr/bin/scp -r -p doc/rdoc/* ezmobius@rubyforge.org:/var/www/gforge-projects/merb}
  end

end

##############################################################################
# rSpec & rcov
##############################################################################
desc "Run :specs, :rcov"
task :aok => [:specs, :rcov]

# desc "Run all specs"
# Spec::Rake::SpecTask.new("specs") do |t|
#   t.spec_opts = ["--format", "specdoc", "--colour"]
#   t.spec_files = Dir["spec/**/*_spec.rb"].sort
# end

def setup_specs(name, spec_cmd='spec')
  desc "Run all specs (#{name})"
  task "specs:#{name}" do
    run_specs("spec/**/*_spec.rb", spec_cmd)
  end

  desc "Run private specs (#{name})"
  task "specs:#{name}:private" do
    run_specs("spec/private/**/*_spec.rb", spec_cmd)
  end

  desc "Run public specs (#{name})"
  task "specs:#{name}:public" do
    run_specs("spec/public/**/*_spec.rb", spec_cmd)
  end
end

setup_specs("mri", "spec")
setup_specs("jruby", "jruby -S spec")

task "specs" => ["specs:mri"]
task "specs:private" => ["specs:mri:private"]
task "specs:public" => ["specs:mri:public"]

desc "Run coverage suite"
task :rcov do
  require 'fileutils'
  FileUtils.rm_rf("coverage") if File.directory?("coverage")
  FileUtils.mkdir("coverage")
  path = File.expand_path(Dir.pwd)
  files = Dir["spec/**/*_spec.rb"]
  files.each do |spec|
    puts "Getting coverage for #{File.expand_path(spec)}"
    command = %{rcov #{File.expand_path(spec)} --aggregate #{path}/coverage/data.data --exclude ".*" --include-file "lib/merb-core(?!\/vendor)"}
    command += " --no-html" unless spec == files.last
    `#{command} 2>&1`
  end
end

desc "Run a specific spec with TASK=xxxx"
Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.libs = ["lib", "server/lib" ]
  t.spec_files = (ENV["TASK"] || '').split(',').map do |task|
    "spec/**/#{task}_spec.rb"
  end
end

desc "Run all specs output html"
Spec::Rake::SpecTask.new("specs_html") do |t|
  t.spec_opts = ["--format", "html"]
  t.libs = ["lib", "server/lib" ]
  t.spec_files = Dir["spec/**/*_spec.rb"].sort
end

# desc "RCov"
# Spec::Rake::SpecTask.new("rcov") do |t|
#   t.rcov_opts = ["--exclude", "gems", "--exclude", "spec"]
#   t.spec_opts = ["--format", "specdoc", "--colour"]
#   t.spec_files = Dir["spec/**/*_spec.rb"].sort
#   t.libs = ["lib", "server/lib"]
#   t.rcov = true
# end

STATS_DIRECTORIES = [
  ['Code', 'lib/'],
  ['Unit tests', 'spec']
].collect { |name, dir| [ name, "./#{dir}" ] }.
  select  { |name, dir| File.directory?(dir) }

desc "Report code statistics (KLOCs, etc) from the application"
task :stats do
  require __DIR__ + "/tools/code_statistics"
  # require "extra/stats"
  verbose = true
  CodeStatistics.new(*STATS_DIRECTORIES).to_s
end

task :release => :package do
  if ENV["RELEASE"]
    sh %{rubyforge add_release merb merb "#{ENV["RELEASE"]}" pkg/#{NAME}-#{Merb::VERSION}.gem}
  else
    puts "Usage: rake release RELEASE='Clever tag line goes here'"
  end
end

##############################################################################
# SYNTAX CHECKING
##############################################################################

task :check_syntax do
  `find . -name "*.rb" |xargs -n1 ruby -c |grep -v "Syntax OK"`
  puts "* Done"
end

##############################################################################
# SVN
##############################################################################
namespace :repo do

  desc "Add new files to repository"
  task :add do
    if File.directory?(".git")
      system "git add *"
    elsif File.directory?(".svn")
      system "svn status | grep '^\?' | sed -e 's/? *//' | sed -e 's/ /\ /g' | xargs svn add"
    end
  end

  desc "Fetch changes from master repository"
  task :rebase do
    if File.directory?(".git")
      system "git stash ; git svn rebase ; git stash apply"
    elsif File.directory?(".svn")
      system "svn update"
    end
  end
  
  desc "commit modified changes to the repository"
  task :commit do
    if File.directory?(".git")
      system "git commit"
    elsif File.directory?(".svn")
      system "svn commit"
    end
  end
  
end

# Run specific tests or test files. Searches nested spec directories as well.
# 
# Based on a technique popularized by Geoffrey Grosenbach
rule "" do |t|
  spec_cmd = (RUBY_PLATFORM =~ /java/) ? "jruby -S spec" : "spec"
  # spec:spec_file:spec_name
  if /spec:(.*)$/.match(t.name)
    arguments = t.name.split(':')
    
    file_name = arguments[1]
    spec_name = arguments[2..-1]

    spec_filename = "#{file_name}_spec.rb"
    specs = Dir["spec/**/#{spec_filename}"]
    
    if path = specs.detect { |f| spec_filename == File.basename(f) }
      run_file_name = path
    else
      puts "No specs found for #{t.name.inspect}"
      exit
    end

    example = " -e '#{spec_name}'" unless spec_name.empty?
    
    sh "#{spec_cmd} #{run_file_name} --format specdoc --colour #{example}"
  end
end
