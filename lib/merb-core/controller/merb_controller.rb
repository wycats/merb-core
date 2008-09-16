class Merb::Controller < Merb::AbstractController

  class_inheritable_accessor :_hidden_actions, :_shown_actions

  self._hidden_actions ||= []
  self._shown_actions  ||= []

  cattr_accessor :_subclasses
  self._subclasses = Set.new

  def self.subclasses_list() _subclasses end

  include Merb::ResponderMixin
  include Merb::ControllerMixin
  include Merb::AuthenticationMixin
  include Merb::ConditionalGetMixin

  class << self

    # ==== Parameters
    # klass<Merb::Controller>::
    #   The Merb::Controller inheriting from the base class.
    def inherited(klass)
      _subclasses << klass.to_s
      super
      klass._template_root = Merb.dir_for(:view) unless self._template_root
    end

    # Hide each of the given methods from being callable as actions.
    #
    # ==== Parameters
    # *names<~to-s>:: Actions that should be added to the list.
    #
    # ==== Returns
    # Array[String]::
    #   An array of actions that should not be possible to dispatch to.
    #
    #---
    # @public
    def hide_action(*names)
      self._hidden_actions = self._hidden_actions | names.map { |n| n.to_s }
    end

    # Makes each of the given methods being callable as actions. You can use
    # this to make methods included from modules callable as actions.
    #
    # ==== Parameters
    # *names<~to-s>:: Actions that should be added to the list.
    #
    # ==== Returns
    # Array[String]::
    #   An array of actions that should be dispatched to even if they would not
    #   otherwise be.
    #
    # ==== Example
    #   module Foo
    #     def self.included(base)
    #       base.show_action(:foo)
    #     end
    #
    #     def foo
    #       # some actiony stuff
    #     end
    #
    #     def foo_helper
    #       # this should not be an action
    #     end
    #   end
    #
    #---
    # @public
    def show_action(*names)
      self._shown_actions = self._shown_actions | names.map {|n| n.to_s}
    end

    # The list of actions that are callable, after taking defaults,
    # _hidden_actions and _shown_actions into consideration. It is calculated
    # once, the first time an action is dispatched for this controller.
    #
    # ==== Returns
    # SimpleSet[String]:: A set of actions that should be callable.
    def callable_actions
      @callable_actions ||= Extlib::SimpleSet.new(_callable_methods)
    end

    # This is a stub method so plugins can implement param filtering if they want.
    #
    # ==== Parameters
    # params<Hash{Symbol => String}>:: A list of params
    #
    # ==== Returns
    # Hash{Symbol => String}:: A new list of params, filtered as desired
    #---
    # @semipublic
    def _filter_params(params)
      params
    end

    private

    # All methods that are callable as actions.
    #
    # ==== Returns
    # Array:: A list of method names that are also actions
    def _callable_methods
      callables = []
      klass = self
      begin
        callables << (klass.public_instance_methods(false) + klass._shown_actions) - klass._hidden_actions
        klass = klass.superclass
      end until klass == Merb::AbstractController || klass == Object
      callables.flatten.reject{|action| action =~ /^_.*/}
    end

  end # class << self

  # The location to look for a template for a particular controller, context,
  # and mime-type. This is overridden from AbstractController, which defines a
  # version of this that does not involve mime-types.
  #
  # ==== Parameters
  # context<~to_s>:: The name of the action or template basename that will be rendered.
  # type<~to_s>::
  #    The mime-type of the template that will be rendered. Defaults to nil.
  # controller<~to_s>::
  #   The name of the controller that will be rendered. Defaults to
  #   controller_name.
  #
  # ==== Notes
  # By default, this renders ":controller/:action.:type". To change this,
  # override it in your application class or in individual controllers.
  #
  #---
  # @public
  def _template_location(context, type, controller)
    _conditionally_append_extension(controller ? "#{controller}/#{context}" : "#{context}", type)
  end

  # The location to look for a template and mime-type. This is overridden
  # from AbstractController, which defines a version of this that does not
  # involve mime-types.
  #
  # ==== Parameters
  # template<String>::
  #    The absolute path to a template - without mime and template extension.
  #    The mime-type extension is optional - it will be appended from the
  #    current content type if it hasn't been added already.
  # type<~to_s>::
  #    The mime-type of the template that will be rendered. Defaults to nil.
  #
  # @public
  def _absolute_template_location(template, type)
    _conditionally_append_extension(template, type)
  end

  # Build a new controller.
  #
  # Sets the variables that came in through the dispatch as available to
  # the controller.
  #
  # ==== Parameters
  # request<Merb::Request>:: The Merb::Request that came in from Rack.
  # status<Integer>:: An integer code for the status. Defaults to 200.
  # headers<Hash{header => value}>::
  #   A hash of headers to start the controller with. These headers can be
  #   overridden later by the #headers method.
  #---
  # @semipublic
  def initialize(request, status=200, headers={'Content-Type' => 'text/html; charset=utf-8'})
    super()
    @request, @_status, @headers = request, status, headers
  end

  # Dispatch the action.
  #
  # ==== Parameters
  # action<~to_s>:: An action to dispatch to. Defaults to :index.
  #
  # ==== Returns
  # String:: The string sent to the logger for time spent.
  #
  # ==== Raises
  # ActionNotFound:: The requested action was not found in class.
  #---
  # @semipublic
  def _dispatch(action=:index)
    Merb.logger.info("Params: #{self.class._filter_params(request.params).inspect}")
    start = Time.now
    if self.class.callable_actions.include?(action.to_s)
      super(action)
    else
      raise ActionNotFound, "Action '#{action}' was not found in #{self.class}"
    end
    @_benchmarks[:action_time] = Time.now - start
    self
  end

  attr_reader :request, :headers

  def status
    @_status
  end

  # Set the response status code.
  #
  # ==== Parameters
  # s<Fixnum, Symbol>:: A status-code or named http-status
  def status=(s)
    if s.is_a?(Symbol) && STATUS_CODES.key?(s)
      @_status = STATUS_CODES[s]
    elsif s.is_a?(Fixnum)
      @_status = s
    else
      raise ArgumentError, "Status should be of type Fixnum or Symbol, was #{s.class}"
    end
  end

  # ==== Returns
  # Hash:: The parameters from the request object
  def params()  request.params  end

  # The results of the controller's render, to be returned to Rack.
  #
  # ==== Returns
  # Array[Integer, Hash, String]::
  #   The controller's status code, headers, and body
  def rack_response
    [status, headers, body]
  end

  # Hide any methods that may have been exposed as actions before.
  hide_action(*_callable_methods)

  private

  # If not already added, add the proper mime extension to the template path.
  def _conditionally_append_extension(template, type)
    type && !template.match(/\.#{type.to_s.escape_regexp}$/) ? "#{template}.#{type}" : template
  end
end
