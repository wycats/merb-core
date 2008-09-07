module Merb
  module ScriptHelpers
    
    # Adapt rubygems - shortcut for setup_local_gems that figures out the
    # local gem path to use.
    def setup_local_gems!(rootdir = nil)
      if bundled? && local_gems = setup_local_gems(File.join(rootdir || merb_root, 'gems'))
        if local_gems.is_a?(Array)
          puts "Using local gems in addition to system gems..."
          if verbose?
            puts "Found #{local_gems.length} local gems:"
            local_gems.each { |name| puts "- #{name}" }
          end
        elsif local_gems
          puts "Using MiniGems to locate local/system gems..."
        end
      elsif use_minigems?
        puts "Using MiniGems to locate system gems..."
      else
        puts "Using system gems..."
      end
    end
    
    # Adapt rubygems - because the /usr/bin/merb script already setup merb-core loadpaths
    # from the system-wide rubygem paths. The code below will make sure local gems always
    # get precedence over system gems and resolves any conflicts that may arise.
    #
    # Only native Gem methods are used to handle the internal logic transparently.
    # These methods are proved either by minigems or standard rubygems.
    #
    # Note: currently the Kernel.load_dependency method will always load local gems.
    def setup_local_gems(gems_path)
      if File.directory?(gems_path)
        if use_minigems?
          # Reset all loaded system gems - replace with local gems
          Gem.clear_paths
          Gem.path.unshift(gems_path)
          return true
        else
          # Remember originally loaded system gems and create a lookup of gems to load paths  
          system_gemspecs = Gem.cache.gems
          system_load_paths = extract_gem_load_paths(system_gemspecs)
          
          # Reset all loaded system gems - replace with local gems
          Gem.clear_paths
          Gem.path.unshift(gems_path)
          Gem.cache.load_gems_in(File.join(gems_path, "specifications"))
          
          # Collect any local gems we're going to use
          local_gems = Gem.cache.map { |name, spec| name }
          
          # Create a lookup of gems to load paths for all local gems
          local_load_paths = extract_gem_load_paths(Gem.cache.gems)
          
          # Filter out local gems from the originally loaded system gems to prevent conflicts
          active_system_gems = []
          system_gemspecs.each do |name, spec|
            active_system_gems << spec unless local_load_paths[spec.name]
          end
          
          # Re-add the system gems - conflicts with local gems have been avoided
          Gem.cache.add_specs(*active_system_gems)
          
          # Add local paths to LOAD_PATH - remove overlapping system gem paths
          local_load_paths.each do |name, paths|
            $LOAD_PATH.unshift(*paths)
            $LOAD_PATH.replace($LOAD_PATH - system_load_paths[name] || [])
          end
          return local_gems
        end
      end
    end
    
    # Figure out the merb root or default to current directory
    def merb_root
      root_key = %w[-m --merb-root].detect { |o| ARGV.index(o) }
      root = ARGV[ARGV.index(root_key) + 1] if root_key
      root.to_a.empty? ? Dir.getwd : root
    end
    
    # See if we're running merb locally - enabled by default
    # The ENV variables are considered for Rakefile usage.
    def bundled?
      enabled  = ENV.key?("BUNDLE")    || %w[-B --bundle].detect { |o| ARGV.index(o) }
      disabled = ENV.key?("NO_BUNDLE") || %w[--no-bundle].detect { |o| ARGV.index(o) }
      enabled || !disabled
    end
    
    # Add some extra feedback if verbose is enabled
    def verbose?
      %w[-V --verbose].detect { |o| ARGV.index(o) }
    end
    
    # Whether minigems has been loaded instead of the full rubygems
    def use_minigems?
      Gem.respond_to?(:minigems?) && Gem.minigems?
    end
    
    # Helper method to extract a Hash lookup of gem name to load paths
    def extract_gem_load_paths(source_index)
      source_index.inject({}) do |load_paths, (name, spec)|
        require_paths = spec.require_paths
        require_paths << spec.bindir unless spec.executables.empty?
        load_paths[spec.name] = require_paths.map do |path| 
          File.join(spec.full_gem_path, path)
        end
        load_paths
      end
    end
    
  end
end