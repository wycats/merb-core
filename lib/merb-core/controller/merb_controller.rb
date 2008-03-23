class Merb::Controller < Merb::AbstractController
  
  class_inheritable_accessor :_hidden_actions, :_shown_actions
  cattr_accessor :_subclasses, :_session_id_key, :_session_secret_key, :_session_expiry
  self._subclasses = Set.new

  def self.subclasses_list() _subclasses end
  
  self._session_secret_key = nil
  self._session_id_key = Merb::Config[:session_id_key] || '_session_id'
  self._session_expiry = Merb::Config[:session_expiry] || Merb::Const::WEEK * 2
  
  include Merb::ResponderMixin
  include Merb::ControllerMixin

  attr_accessor :route
  
  class << self
    
    # ==== Parameters
    # klass<Merb::Controller>::
    #   The Merb::Controller inheriting from the base class.
    def inherited(klass)
      _subclasses << klass.to_s
      self._template_root = Merb.dir_for(:view) unless self._template_root
      super
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

    # This list of actions that should not be callable.
    # 
    # ==== Returns
    # Array[String]:: An array of actions that should not be dispatchable.
    def _hidden_actions
      actions = read_inheritable_attribute(:_hidden_actions)
      actions ? actions : write_inheritable_attribute(:_hidden_actions, [])
    end

    # This list of actions that should be callable.
    # 
    # ==== Returns
    # Array[String]::
    #   An array of actions that should be dispatched to even if they would not
    #   otherwise be.
    def _shown_actions
      actions = read_inheritable_attribute(:_shown_actions)
      actions ? actions : write_inheritable_attribute(:_shown_actions, [])      
    end

    # The list of actions that are callable, after taking defaults,
    # _hidden_actions and _shown_actions into consideration. It is calculated
    # once, the first time an action is dispatched for this controller.
    #
    # ==== Returns
    # Array[String]:: A list of actions that should be callable.
    def callable_actions
      unless @callable_actions
        callables = []
        klass = self
        begin
          callables << (klass.public_instance_methods(false) + klass._shown_actions) - klass._hidden_actions
          klass = klass.superclass
        end until klass == Merb::Controller || klass == Object
        @callable_actions = Merb::SimpleSet.new(callables.flatten)
      end
      @callable_actions
    end
    
  end
  
  # The location to look for a template for a particular controller, action,
  # and mime-type. This is overridden from AbstractController, which defines a
  # version of this that does not involve mime-types.
  #
  # ==== Parameters
  # action<~to_s>:: The name of the action that will be rendered.
  # type<~to_s>::
  #    The mime-type of the template that will be rendered. Defaults to nil.
  # controller<~to_s>::
  #   The name of the controller that will be rendered. Defaults to
  #   controller_name.
  #
  # ==== Note
  # By default, this renders ":controller/:action.:type". To change this,
  # override it in your application class or in individual controllers.
  #
  #---
  # @public
  def _template_location(action, type = nil, controller = controller_name)
    "#{controller}/#{action}.#{type}"
  end  
  
  # Build a new controller.
  #
  # Sets the variables that came in through the dispatch as available to
  # the controller. 
  #
  # This method uses the :session_id_cookie_only and :query_string_whitelist
  # configuration options. See CONFIG for more details.
  #
  # ==== Parameters
  # request<Merb::Request>:: The Merb::Request that came in from Mongrel.
  # status<Integer>:: An integer code for the status. Defaults to 200.
  # headers<Hash{header => value}>:: 
  #   A hash of headers to start the controller with. These headers can be
  #   overridden later by the #headers method.
  #---
  # @semipublic
  def initialize(request, status=200, headers={'Content-Type' => 'text/html; charset=utf-8'})
    super()
    @request, @status, @headers = request, status, headers
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
    start = Time.now
    if self.class.callable_actions.include?(action.to_s)
      super(action)
    else
      raise ActionNotFound, "Action '#{action}' was not found in #{self.class}"
    end
    @_benchmarks[:action_time] = Time.now - start
  end
  
  attr_reader :request, :headers
  attr_accessor :status
  
  # ==== Returns
  # Hash:: The parameters from the request object
  def params()  request.params  end
    
  # ==== Returns
  # Merb::Cookies:: 
  #   A new Merb::Cookies instance representing the cookies that came in
  #   from the request object
  #
  # ==== Note
  # Headers are passed into the cookie object so that you can do:
  #   cookies[:foo] = "bar"
  def cookies() @_cookies ||= _setup_cookies end
    
  # ==== Returns
  # Hash:: The session that was extracted from the request object.
  def session() request.session end
    
  private

  # Create a default cookie jar, and pre-set a fixation cookie
  # if fixation is enabled
  def _setup_cookies
    cookies = ::Merb::Cookies.new(request.cookies, @headers)
    if request.params.key?(_session_id_key) && route.allow_fixation?
      cookies[_session_id_key] = request.params[_session_id_key]
    end
    cookies
  end
end
