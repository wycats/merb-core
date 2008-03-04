# Based on Spec::Rails::Example::ModelExampleGroup from RSpec

module Merb::Test::Rspec::Example
  # Model Specs live in spec/models/.
  #
  # Model Specs use Merb::Test::Rspec::Example::ModelExampleGroup.
  class ModelExampleGroup < MerbExampleGroup
    Spec::Example::ExampleGroupFactory.register(:model, self)
  end
end