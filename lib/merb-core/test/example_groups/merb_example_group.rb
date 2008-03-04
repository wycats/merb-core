module Merb::Test::Rspec::Example
  class MerbExampleGroup < Spec::ExampleGroup
    # include Merb::Test::Rspec::MerbMatchers
    
    Spec::Example::ExampleGroupFactory.default(self)
  end
end