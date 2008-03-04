# Based on Spec::Rails::Example::HelperExampleGroup from RSpec

module Merb::Test::Rspec::Example
  # Helper Specs live in spec/helpers/.
  #
  # Helper Specs use Merb::Test::Rspec::Example::HelperExampleGroup, which
  # allows you to include your Helper directly in the context and write specs
  # directly against its methods.
  #
  # To automatically include a helper module into your spec, you pass the helper
  # name to #describe:
  #
  #   describe Merb::ThingHelper do
  #     ...
  #
  # ==== Example
  #
  #   module Merb
  #     module DeepThought
  #       def ultimate_answer
  #         42
  #       end
  #     end
  #   end
  #
  #   describe Merb::DeepThought do
  #     it "should tell you the answer to the ultimate question" do
  #       ultimate_answer.should == 42
  #     end
  #   end
  class HelperExampleGroup < MerbExampleGroup
    Spec::Example::ExampleGroupFactory.register(:helper, self)
  end
end