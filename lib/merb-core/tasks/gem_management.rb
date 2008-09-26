require 'rubygems'
require 'rubygems/dependency_installer'
require 'rubygems/uninstaller'
require 'rubygems/dependency'

module GemManagement
  
  # Install a gem - looks remotely and local gem cache;
  # won't process rdoc or ri options.
  def install_gem(gem, options = {})
    from_cache = (options.key?(:cache) && options.delete(:cache))
    if from_cache
      install_gem_from_cache(gem, options)
    else
      version = options.delete(:version)
      Gem.configuration.update_sources = false

      update_source_index(options[:install_dir]) if options[:install_dir]

      installer = Gem::DependencyInstaller.new(options.merge(:user_install => false))
      exception = nil
      begin
        installer.install gem, version
      rescue Gem::InstallError => e
        exception = e
      rescue Gem::GemNotFoundException => e
        if from_cache && gem_file = find_gem_in_cache(gem, version)
          puts "Located #{gem} in gem cache..."
          installer.install gem_file
        else
          exception = e
        end
      rescue => e
        exception = e
      end
      if installer.installed_gems.empty? && exception
        puts "Failed to install gem '#{gem} (#{version})' (#{exception.message})"
      end
      installer.installed_gems.each do |spec|
        puts "Successfully installed #{spec.full_name}"
      end
      return !installer.installed_gems.empty?
    end
  end

  # Install a gem - looks in the system's gem cache instead of remotely;
  # won't process rdoc or ri options.
  def install_gem_from_cache(gem, options = {})
    version = options.delete(:version)
    Gem.configuration.update_sources = false
    installer = Gem::DependencyInstaller.new(options.merge(:user_install => false))
    exception = nil
    begin
      if gem_file = find_gem_in_cache(gem, version)
        puts "Located #{gem} in gem cache..."
        installer.install gem_file
      else
        raise Gem::InstallError, "Unknown gem #{gem}"
      end
    rescue Gem::InstallError => e
      exception = e
    end
    if installer.installed_gems.empty? && exception
      puts "Failed to install gem '#{gem}' (#{e.message})"
    end
    installer.installed_gems.each do |spec|
      puts "Successfully installed #{spec.full_name}"
    end
  end

  # Install a gem from source - builds and packages it first then installs.
  def install_gem_from_src(gem_src_dir, options = {})
    if !File.directory?(gem_src_dir)
      raise "Missing rubygem source path: #{gem_src_dir}"
    end
    if options[:install_dir] && !File.directory?(options[:install_dir])
      raise "Missing rubygems path: #{options[:install_dir]}"
    end

    gem_name = File.basename(gem_src_dir)
    gem_pkg_dir = File.expand_path(File.join(gem_src_dir, 'pkg'))

    # We need to use local bin executables if available.
    thor = "#{Gem.ruby} -S #{which('thor')}"
    rake = "#{Gem.ruby} -S #{which('rake')}"

    # Handle pure Thor installation instead of Rake
    if File.exists?(File.join(gem_src_dir, 'Thorfile'))
      # Remove any existing packages.
      FileUtils.rm_rf(gem_pkg_dir) if File.directory?(gem_pkg_dir)
      # Create the package.
      FileUtils.cd(gem_src_dir) { system("#{thor} :package") }
      # Install the package using rubygems.
      if package = Dir[File.join(gem_pkg_dir, "#{gem_name}-*.gem")].last
        FileUtils.cd(File.dirname(package)) do
          install_gem(File.basename(package), options.dup)
          return
        end
      else
        raise Gem::InstallError, "No package found for #{gem_name}"
      end
    # Handle standard installation through Rake
    else
      # Clean and regenerate any subgems for meta gems.
      Dir[File.join(gem_src_dir, '*', 'Rakefile')].each do |rakefile|
        FileUtils.cd(File.dirname(rakefile)) { system("#{rake} clobber_package; #{rake} package") }
      end

      # Handle the main gem install.
      if File.exists?(File.join(gem_src_dir, 'Rakefile'))
        # Remove any existing packages.
        FileUtils.cd(gem_src_dir) { system("#{rake} clobber_package") }
        # Create the main gem pkg dir if it doesn't exist.
        FileUtils.mkdir_p(gem_pkg_dir) unless File.directory?(gem_pkg_dir)
        # Copy any subgems to the main gem pkg dir.
        Dir[File.join(gem_src_dir, '**', 'pkg', '*.gem')].each do |subgem_pkg|
          dest = File.join(gem_pkg_dir, File.basename(subgem_pkg))
          FileUtils.copy_entry(subgem_pkg, dest, false, false, true)
        end

        # Finally generate the main package and install it; subgems
        # (dependencies) are local to the main package.
        FileUtils.cd(gem_src_dir) do
          system("#{rake} package")
          FileUtils.cd(gem_pkg_dir) do
            if package = Dir[File.join(gem_pkg_dir, "#{gem_name}-*.gem")].last
              # If the (meta) gem has it's own package, install it.
              install_gem(File.basename(package), options.dup)
            else
              # Otherwise install each package seperately.
              Dir["*.gem"].each { |gem| install_gem(gem, options.dup) }
            end
          end
          return
        end
      end
    end
    raise Gem::InstallError, "No Rakefile found for #{gem_name}"
  end

  # Uninstall a gem.
  def uninstall_gem(gem, options = {})
    if options[:version] && !options[:version].is_a?(Gem::Requirement)
      options[:version] = Gem::Requirement.new ["= #{options[:version]}"]
    end
    update_source_index(options[:install_dir]) if options[:install_dir]
    Gem::Uninstaller.new(gem, options).uninstall
  end

  # Use the local bin/* executables if available.
  def which(executable)
    if File.executable?(exec = File.join(Dir.pwd, 'bin', executable))
      exec
    else
      executable
    end
  end
  
  # Create a modified executable wrapper in the specified bin directory.
  def ensure_bin_wrapper_for(gem_dir, bin_dir, *gems)
    if bin_dir && File.directory?(bin_dir)
      gems.each do |gem|
        if gemspec_path = Dir[File.join(gem_dir, 'specifications', "#{gem}-*.gemspec")].last
          spec = Gem::Specification.load(gemspec_path)
          spec.executables.each do |exec|
            executable = File.join(bin_dir, exec)
            puts "Writing executable wrapper #{executable}"
            File.open(executable, 'w', 0755) do |f|
              f.write(executable_wrapper(spec, exec))
            end
          end
        end
      end
    end
  end

  private

  def executable_wrapper(spec, bin_file_name)
    <<-TEXT
#!#{Gem.ruby}
#
# This file was generated by Merb's GemManagement
#
# The application '#{spec.name}' is installed as part of a gem, and
# this file is here to facilitate running it.

begin 
  require 'minigems'
rescue LoadError 
  require 'rubygems'
end

if File.directory?(gems_dir = File.join(Dir.pwd, 'gems'))
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(gems_dir)
end

version = "#{Gem::Requirement.default}"

if ARGV.first =~ /^_(.*)_$/ and Gem::Version.correct? $1 then
  version = $1
  ARGV.shift
end

gem '#{spec.name}', version
load '#{bin_file_name}'
TEXT
  end

  def find_gem_in_cache(gem, version)
    spec = if version
      version = Gem::Requirement.new ["= #{version}"] unless version.is_a?(Gem::Requirement)
      Gem.source_index.find_name(gem, version).first
    else
      Gem.source_index.find_name(gem).sort_by { |g| g.version }.last
    end
    if spec && File.exists?(gem_file = "#{spec.installation_path}/cache/#{spec.full_name}.gem")
      gem_file
    end
  end

  def update_source_index(dir)
    Gem.source_index.load_gems_in(File.join(dir, 'specifications'))
  end
  
end