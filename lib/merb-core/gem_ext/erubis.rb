require 'erubis'
module Erubis
  
  class MEruby < Erubis::Eruby
    include PercentLineEnhancer
    include StringBufferEnhancer
  end

  # Loads a file, runs it through Erubis and parses it as YAML.
  #
  # ===== Parameters
  # file<String>:: The name of the file to load.
  # binding<Binding>::
  #   The binding to use when evaluating the ERB tags. Defaults to the current
  #   binding.
  def self.load_yaml_file(file, binding = binding)
    YAML::load(Erubis::MEruby.new(IO.read(File.expand_path(file))).result(binding))
  end
end