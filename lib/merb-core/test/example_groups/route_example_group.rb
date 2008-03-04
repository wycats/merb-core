module Merb::Test::Rspec::Example
  # Model Specs live in spec/route/.
  #
  # Model Specs use Merb::Test::Rspec::Example::RouteExampleGroup.
  class RouteExampleGroup < MerbExampleGroup
    include Merb::Test::Rspec::RouteMatchers
    
    Spec::Example::ExampleGroupFactory.register(:route, self)
  end
end