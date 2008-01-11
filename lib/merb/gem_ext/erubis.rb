require 'erubis'
module Erubis
  class MEruby < Erubis::Eruby
    include PercentLineEnhancer
    include StringBufferEnhancer
  end
  def self.load_yaml_file(file, binding = binding)
    YAML::load(Erubis::MEruby.new(IO.read(File.expand_path(file))).result(binding))
  end
end