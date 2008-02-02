

# DOC: Ezra Zygmuntowicz FAILED
module Merb
  
  # DOC: Ezra Zygmuntowicz FAILED
  module Plugins
    
    # DOC: Ezra Zygmuntowicz FAILED
    def self.config
      @config ||= File.exists?(Merb.root / "config" / "plugins.yml") ? YAML.load(File.read(Merb.root / "config" / "plugins.yml")) || {} : {}
    end
    
    @rakefiles = []

    # DOC: Ezra Zygmuntowicz FAILED
    def self.rakefiles
      @rakefiles
    end

    # DOC: Ezra Zygmuntowicz FAILED
    def self.add_rakefiles(*rakefiles)
      @rakefiles += rakefiles
    end
  end
end