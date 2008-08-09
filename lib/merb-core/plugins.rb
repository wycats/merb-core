module Merb

  module Plugins

    # ==== Returns
    # Hash::
    #   The configuration loaded from Merb.root / "config/plugins.yml" or, if
    #   the load fails, an empty hash whose default value is another Hash.
    def self.config
      @config ||= begin
        # this is so you can do Merb.plugins.config[:helpers][:awesome] = "bar"
        config_hash = Hash.new {|h,k| h[k] = {}}
        file = Merb.root / "config" / "plugins.yml"
        config_hash.merge((File.exists?(file) && YAML.load_file(file)) || {})
      end
    end

    # ==== Returns
    # Array(String):: All Rakefile load paths Merb uses for plugins.
    def self.rakefiles
      Merb.rakefiles
    end
    
    # ==== Returns
    # Array(String):: All Generator load paths Merb uses for plugins.
    def self.generators
      Merb.generators
    end

    # ==== Parameters
    # *rakefiles:: Rakefiles to add to the list of plugin Rakefiles.
    #
    # ==== Notes
    #
    # This is a recommended way to register your plugin's Raketasks
    # in Merb.
    #
    # ==== Examples
    # From merb_sequel plugin:
    #
    # if defined(Merb::Plugins)
    #   Merb::Plugins.add_rakefiles "merb_sequel" / "merbtasks"
    # end
    def self.add_rakefiles(*rakefiles)
      Merb.add_rakefiles(*rakefiles)
    end
    
    # ==== Parameters
    # *generators:: Generator paths to add to the list of plugin generators.
    #
    # ==== Notes
    #
    # This is the recommended way to register your plugin's generators
    # in Merb.
    def self.add_generators(*generators)
      Merb.add_generators(*generators)
    end
  end
end
