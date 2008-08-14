require "rake"
require "rake/clean"
require "rake/gempackagetask"
require "rake/rdoctask"
require "rake/testtask"
require "spec/rake/spectask"
require "fileutils"
require "extlib"

def __DIR__
  File.dirname(__FILE__)
end

require __DIR__ + "/tools/rakehelp"
require __DIR__ + "/tools/annotation_extract"

include FileUtils

require "lib/merb-core/version"
require "lib/merb-core/test/run_specs"
require 'lib/merb-core/tasks/merb_rake_helper'

##############################################################################
# Package && release
##############################################################################
RUBY_FORGE_PROJECT  = "merb"
PROJECT_URL         = "http://merbivore.com"
PROJECT_SUMMARY     = "Merb. Pocket rocket web framework."
PROJECT_DESCRIPTION = PROJECT_SUMMARY

AUTHOR = "Ezra Zygmuntowicz"
EMAIL  = "ez@engineyard.com"

GEM_NAME    = "merb-core"
PKG_BUILD   = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
GEM_VERSION = Merb::VERSION + PKG_BUILD

RELEASE_NAME    = "REL #{GEM_VERSION}"

require "extlib/tasks/release"

spec = Gem::Specification.new do |s|
  s.name         = GEM_NAME
  s.version      = GEM_VERSION
  s.platform     = Gem::Platform::RUBY
  s.author       = AUTHOR
  s.email        = EMAIL
  s.homepage     = PROJECT_URL
  s.summary      = PROJECT_SUMMARY
  s.bindir       = "bin"
  s.description  = PROJECT_DESCRIPTION
  s.executables  = %w( merb )
  s.require_path = "lib"
  s.files        = %w( LICENSE README Rakefile TODO ) + Dir["{docs,bin,spec,lib,examples,app_generators,merb_generators,merb_default_generators,rspec_generators,test_unit_generators,script}/**/*"]

  # rdoc
  s.has_rdoc         = true
  s.extra_rdoc_files = %w( README LICENSE TODO )
  #s.rdoc_options     += RDOC_OPTS + ["--exclude", "^(app|uploads)"]

  # Dependencies
  s.add_dependency "extlib", ">=0.9.3"
  s.add_dependency "erubis"
  s.add_dependency "rake"
  s.add_dependency "json_pure"
  s.add_dependency "rspec"
  s.add_dependency "rack"
  s.add_dependency "mime-types"
  # Requirements
  s.requirements << "install the json gem to get faster json parsing"
  s.required_ruby_version = ">= 1.8.6"
end

Rake::GemPackageTask.new(spec) do |package|
  package.gem_spec = spec
end

desc "Run :package and install the resulting .gem"
task :install => :package do
  sh %{#{sudo} gem install #{install_home} --local pkg/#{GEM_NAME}-#{GEM_VERSION}.gem --no-rdoc --no-ri}
end

desc "Run :package and install the resulting .gem with jruby"
task :jinstall => :package do
  sh %{#{sudo} jruby -S gem install #{install_home} pkg/#{NAME}-#{Merb::VERSION}.gem --no-rdoc --no-ri}
end

desc "Run :clean and uninstall the .gem"
task :uninstall => :clean do
  sh %{#{sudo} gem uninstall #{NAME}}
end

CLEAN.include ["**/.*.sw?", "pkg", "lib/*.bundle", "*.gem", "doc/rdoc", ".config", "coverage", "cache"]

desc "Run the specs."
task :default => :specs

task :merb => [:clean, :rdoc, :package]

##############################################################################
# Github
##############################################################################
namespace :github do
  desc "Update Github Gemspec"
  task :update_gemspec do
    skip_fields = %w(new_platform original_platform)
    integer_fields = %w(specification_version)

    result = "Gem::Specification.new do |s|\n"
    spec.instance_variables.each do |ivar|
      value = spec.instance_variable_get(ivar)
      name  = ivar.split("@").last
      next if skip_fields.include?(name) || value.nil? || value == "" || (value.respond_to?(:empty?) && value.empty?)
      if name == "dependencies"
        value.each do |d|
          dep, *ver = d.to_s.split(" ")
          result <<  "  s.add_dependency #{dep.inspect}, #{ver.join(" ").inspect.gsub(/[()]/, "")}\n"
        end
      else
        case value
        when Array
          value =  name != "files" ? value.inspect : value.inspect.split(",").join(",\n")
        when String
          value = value.to_i if integer_fields.include?(name)
          value = value.inspect
        else
          value = value.to_s.inspect
        end
        result << "  s.#{name} = #{value}\n"
      end
    end
    result << "end"
    File.open(File.join(File.dirname(__FILE__), "#{spec.name}.gemspec"), "w"){|f| f << result}
  end
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
    sh %{#{sudo} chmod -R 755 doc} unless windows?
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

def setup_specs(name, spec_cmd='spec', run_opts = "-c -f s")
  desc "Run all specs (#{name})"
  task "specs:#{name}" do
    run_specs("spec/**/*_spec.rb", spec_cmd, ENV['RSPEC_OPTS'] || run_opts)
  end

  desc "Run private specs (#{name})"
  task "specs:#{name}:private" do
    run_specs("spec/private/**/*_spec.rb", spec_cmd, ENV['RSPEC_OPTS'] || run_opts)
  end

  desc "Run public specs (#{name})"
  task "specs:#{name}:public" do
    run_specs("spec/public/**/*_spec.rb", spec_cmd, ENV['RSPEC_OPTS'] || run_opts)
  end

  # With profiling formatter
  desc "Run all specs (#{name}) with profiling formatter"
  task "specs:#{name}_profiled" do
    run_specs("spec/**/*_spec.rb", spec_cmd, "-c -f o")
  end

  desc "Run private specs (#{name}) with profiling formatter"
  task "specs:#{name}_profiled:private" do
    run_specs("spec/private/**/*_spec.rb", spec_cmd, "-c -f o")
  end

  desc "Run public specs (#{name}) with profiling formatter"
  task "specs:#{name}_profiled:public" do
    run_specs("spec/public/**/*_spec.rb", spec_cmd, "-c -f o")
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

def git_log(since_release = nil, log_format = "%an")
  git_log_query = "git log --pretty='format:#{log_format}' --no-merges"
  git_log_query << " --since='v#{since_release}'" if since_release
  puts
  puts "Running #{git_log_query}"
  puts
  `#{git_log_query}`
end

def contributors(since_release = nil)
  @merb_contributors ||= git_log(since_release).split("\n").uniq.sort
end

PREVIOUS_RELEASE = '0.9.4'
namespace :history do
  namespace :update do
    desc "updates contributors list"
    task :contributors do
      list = contributors.join "\n"

      path = File.join(File.dirname(__FILE__), 'CONTRIBUTORS')

      rm path if File.exists?(path)

      puts "Writing contributors (#{contributors.size} entries)."
      # windows needs wb
      File.open(path, "wb") do |io|
        io << "Use #{RUBY_FORGE_PROJECT}? Say thanks the following people:\n\n"
        io << list
      end
    end
  end

  
  namespace :alltime do
    desc 'shows all-time committers'
    task :contributors do
      puts 'All-time contributors (#{contributors.size} total): '
      puts '=============================='
      puts
      puts contributors.join("\n")
    end
  end
  
  namespace :current_release do
    desc "show changes since previous release"
    task :changes do
      puts git_log(PREVIOUS_RELEASE, "* %s")
    end


    desc 'shows current release committers'
    task :contributors do
      puts "Current release contributors (#{contributors.size} total): "
      puts '=============================='
      puts
      puts contributors(PREVIOUS_RELEASE).join("\n")
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

##############################################################################
# Flog
##############################################################################

namespace :flog do
  task :worst_methods do
    require "flog"
    flogger = Flog.new
    flogger.flog_files Dir["lib/**/*.rb"]
    totals = flogger.totals.sort_by {|k,v| v}.reverse[0..10]
    totals.each do |meth, total|
      puts "%50s: %s" % [meth, total]
    end
  end
  
  task :total do
    require "flog"
    flogger = Flog.new
    flogger.flog_files Dir["lib/**/*.rb"]
    puts "Total: #{flogger.total}"
  end
  
  task :per_method do
    require "flog"
    flogger = Flog.new
    flogger.flog_files Dir["lib/**/*.rb"]
    methods = flogger.totals.reject { |k,v| k =~ /\#none$/ }.sort_by { |k,v| v }
    puts "Total Flog:    #{flogger.total}"
    puts "Total Methods: #{flogger.totals.size}"
    puts "Flog / Method: #{flogger.total / methods.size}"
  end
end

namespace :tools do
  namespace :tags do
    desc "Generates Emacs tags using Exuberant Ctags."
    task :emacs do
      sh "ctags -e --Ruby-kinds=-f -o TAGS -R lib"
    end
  end
end
