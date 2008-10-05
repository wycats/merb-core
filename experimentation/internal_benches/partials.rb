require File.join(File.dirname(__FILE__), "..", "..", "lib", "merb-core")

class TestController < Merb::AbstractController
  self._template_root = File.dirname(__FILE__) / "partials_views"
  def _template_location(context, type = nil, controller = controller_name)
    "#{context}"
  end
end

include Merb::Test::RequestHelper

controller = TestController.new(fake_request)

require 'rbench'

RBench.run(10_000) do
  report "partial" do
    controller.partial(:partial, :a => 1, :b => 2, :c => 3, :d => 4)
  end
end