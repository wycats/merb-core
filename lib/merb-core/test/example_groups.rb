# Based on Spec::Rails::Example from RSpec

# Merb::Test::Rspec::Example extends Spec::Example (RSpec's core Example module)
# to provide Merb-specific contexts for describing Merb Models, Views,
# Controllers and Helpers.
#
# === Model Examples
# See Merb::Test::Rspec::ModelExampleGroup.
#
# === Controller Examples
# See Merb::Test::Rspec::ControllerExampleGroup.
#
# === View Examples
# See Merb::Test::Rspec::ViewExampleGroup.
#
# === Helper Examples
# See Merb::Test::Rspec::HelperExampleGroup.
#
# === Route Examples
# See Merb::Test::Rspec::RouteExampleGroup.
#
module Merb::Test::Rspec::Example; end

require "merb-core/test/example_groups/merb_example_group"
require "merb-core/test/example_groups/model_example_group"
require "merb-core/test/example_groups/controller_example_group"
require "merb-core/test/example_groups/helper_example_group"
require "merb-core/test/example_groups/view_example_group"
require "merb-core/test/example_groups/route_example_group"