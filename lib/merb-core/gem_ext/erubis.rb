require 'erubis'

# DOC: Yehuda Katz FAILED
module Erubis
  
  # DOC: Yehuda Katz FAILED
  class MEruby < Erubis::Eruby
    include PercentLineEnhancer
    include StringBufferEnhancer
  end

  # DOC: Yehuda Katz FAILED
  def self.load_yaml_file(file, binding = binding)
    YAML::load(Erubis::MEruby.new(IO.read(File.expand_path(file))).result(binding))
  end
end