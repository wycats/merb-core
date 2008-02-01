module Merb
  module Plugins
    def self.config
      @config ||= File.exists?(Merb.root / "config" / "plugins.yml") ? YAML.load(File.read(Merb.root / "config" / "plugins.yml")) || {} : {}
    end
    
    @rakefiles = []
    def self.rakefiles
      @rakefiles
    end
    
    def self.add_rakefiles(*rakefiles)
      @rakefiles += rakefiles
    end
  end
end