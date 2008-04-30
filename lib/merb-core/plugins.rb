module Merb

  module Plugins

    # ==== Returns
    # Hash::
    #   The configuration loaded from Merb.root / "config/plugins.yml" or, if
    #   the load fails, an empty hash.
    def self.config
      @config ||= File.exists?(Merb.root / "config" / "plugins.yml") ? YAML.load(File.read(Merb.root / "config" / "plugins.yml")) || {} : {}
    end

    # ==== Returns
    # Array(String):: All Rakefile load paths Merb uses for plugins.
    def self.rakefiles
      Merb.rakefiles
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
      Merb.add_rakefiles *rakefiles
    end
  end
end
