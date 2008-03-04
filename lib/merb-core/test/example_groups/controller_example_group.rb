# Based on Spec::Rails::Example::ControllerExampleGroup from RSpec

module Merb::Test::Rspec::Example
  # Controller Specs live in spec/controllers/.
  #
  # Controller Specs use Merb::Test::Rspec::Example::ControllerExampleGroup.
  #
  # You MUST provide your controller's name within the context of your
  # controller specs. You can either do this by directly passing the
  # controller name to #describe:
  #
  #   describe Accounts do
  #     ...
  #
  # Or you can use #controller_name to declare the controller name
  # explicitly:
  #
  #   describe "The Accounts Controller" do
  #     controller_name 'accounts'
  #     ...
  #
  # It is recommended to spec the controller completely independent of the
  # view. To do this you simply stub/mock the render method::
  #
  #   describe Accounts, "show action" do
  #     before(:each) do
  #       dispatch(:show, :id => 42) do |controller|
  #         controller.stub!(:render)
  #       end
  #       ...
  #
  # Combined w/ separate view specs, this also provides better fault
  # isolation.
  #
  class ControllerExampleGroup < MerbExampleGroup
    class << self
      def controller_name(name)
        @controller_class_name = "#{name}".camel_case
      end
      attr_accessor :controller_class_name # :nodoc:
    end

    include Merb::Test::Rspec::ControllerMatchers

    before(:each) do
      @controller_class = @controller_class_name.split('::').inject(Object) { |k,n| k.const_get n } rescue nil
      raise "Can't determine controller class for #{@controller_class_name}" if @controller_class.nil?

      unless @controller_class.ancestors.include?(::Merb::Controller)
        Spec::Expectations.fail_with <<-EOE
You have to declare the controller name in controller specs. For example:
  describe "The Accounts Controller" do
    controller_name "accounts" #invokes the controller Accounts
    ...
  end
EOE
      end
    end

    def initialize(defined_description, &implementation) #:nodoc:
      super
      if controller_class_name = self.class.controller_class_name
        @controller_class_name = controller_class_name.to_s
      elsif controller_class_name = self.class.superclass.controller_class_name
        self.class.controller_class_name = controller_class_name
        @controller_class_name = controller_class_name.to_s
      else
        @controller_class_name = self.class.described_type.to_s
      end
    end

    # Dispatches an action to the current class. This bypasses the router and is
    # suitable for unit testing of controllers.
    #
    # ==== Parameters
    # action<Symbol>:: The action name, as a symbol.
    # params<Hash>::
    #   An optional hash that will end up as params in the controller instance.
    # env<Hash>::
    #   An optional hash that is passed to the fake request. Any request options
    #   should go here (see +fake_request+).
    # &blk::
    #   The controller is yielded to the block provided for actions *prior* to
    #   the action being dispatched.
    #
    # ==== Example
    #   dispatch_to(:create, :name => 'Homer' ) do |controller|
    #     controller.stub!(:current_user).and_return(@user)
    #   end
    #
    #---
    # @public
    def dispatch(action = :index, params = {}, env = {}, &block)
      dispatch_to(@controller_class, action, params, env, &block)
    end

    Spec::Example::ExampleGroupFactory.register(:controller, self)
  end
end