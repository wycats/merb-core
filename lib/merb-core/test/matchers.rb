module Merb::Test::Rspec; end

require "merb-core/test/matchers/controller_matchers"
require "merb-core/test/matchers/route_matchers"
require "merb-core/test/matchers/view_matchers"

Merb::Test::ControllerHelper.send(:include, Merb::Test::Rspec::ControllerMatchers)
Merb::Test::RouteHelper.send(:include, Merb::Test::Rspec::RouteMatchers)
Merb::Test::ViewHelper.send(:include, Merb::Test::Rspec::ViewMatchers)