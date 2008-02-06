

# DOC: Yehuda Katz FAILED
class Merb::Controller < Merb::AbstractController
  
  class_inheritable_accessor :_session_id_key, :_session_expiry, :_hidden_actions, :_shown_actions
  cattr_accessor :_subclasses, :_session_secret_key
  self._subclasses = Set.new

  # DOC: Yehuda Katz FAILED
  def self.subclasses_list() _subclasses end
  
  self._session_secret_key = nil
  self._session_id_key = '_session_id'
  self._session_expiry = Time.now + Merb::Const::WEEK * 2
  
  include Merb::ResponderMixin
  include Merb::ControllerMixin
  
  class << self
    
    # ==== Parameters
    # klass<Merb::Controller>:: The Merb::Controller inheriting from the
    #                           base class

    def inherited(klass)
      _subclasses << klass.to_s
      super
    end

    # Hide each of the given methods from being callable as actions.
    #
    # ==== Parameters
    # *names<~to-s>:: Actions that should be added to the list 
    #
    # ==== Returns
    # Array[String]::
    #   An array of actions that should not be possible to dispatch to
    # 
    #---
    # @public

    def hide_action(*names)
      self._hidden_actions = self._hidden_actions | names.map { |n| n.to_s }
    end

    # Makes each of the given methods being callable as actions.
    # You can use this to make methods included from modules callable
    # as actions.
    #
    # ==== Example
    # {{[
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
    # ]}}
    #
    # ==== Parameters
    # *names<~to-s>:: Actions that should be added to the list 
    #
    # ==== Returns
    # Array[String]::
    #   An array of actions that should be dispatched to even if they
    #   would not otherwise be.
    # 
    #---
    # @public

    def show_action(*names)
      self._shown_actions = self._shown_actions | names.map {|n| n.to_s}
    end

    # This list of actions that should not be callable
    # 
    # ==== Returns
    # Array[String]::
    #   An array of actions that should not be dispatchable
    def _hidden_actions
      actions = read_inheritable_attribute(:_hidden_actions)
      actions ? actions : write_inheritable_attribute(:_hidden_actions, [])
    end

    # This list of actions that should be callable
    # 
    # ==== Returns
    # Array[String]::
    #   An array of actions that should be dispatched to even if they
    #   would not otherwise be.
    def _shown_actions
      actions = read_inheritable_attribute(:_shown_actions)
      actions ? actions : write_inheritable_attribute(:_shown_actions, [])      
    end

    # The list of actions that are callable, after taking defaults, _hidden_actions
    # and _shown_actions into consideration. It is calculated once, the first time 
    # an action is dispatched for this controller.
    #
    # ==== Returns
    # Array[String]::
    #   A list of actions that should be callable.

    def callable_actions
      @callable_actions ||= Merb::SimpleSet.new(begin
        callables = []
        klass = self
        begin
          callables << (klass.public_instance_methods(false) + klass._shown_actions) - klass._hidden_actions
          klass = klass.superclass
        end until klass == Merb::Controller || klass == Object
        callables
      end.flatten)
    end
    
  end
  
  # The location to look for a template for a particular controller, action, and
  # mime-type. This is overridden from AbstractController, which defines a version
  # of this that does not involve mime-types.
  #
  # ==== Parameters
  # action<~to_s>:: The name of the action that will be rendered
  # type<~to_s>:: The mime-type of the template that will be rendered
  # controller<~to_s>:: The name of the controller that will be rendered
  #
  # ==== Note
  # By default, this renders ":controller/:action.:type". To change this, override
  # it in your application class or in individual controllers.
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
  # request<Merb::Request>:: The Merb::Request that came in from Mongrel
  # response<IO>:: 
  #   The response IO object to write the response to. This could be any
  #   IO object, but is probably an HTTPResponse
  # status<Integer>:: An integer code for the status
  # headers<Hash{header => value}>:: 
  #   A hash of headers to start the controller with. These headers
  #   can be overridden later by the #headers method
  #
  # ==== Returns
  # Merb::Controller::
  #   The Merb::Controller that was built from the parameters
  # 
  #---
  # @semipublic

  def initialize(request, response = StringIO.new, status=200, headers={'Content-Type' => 'text/html; charset=utf-8'})
    super()
    if request.params.key?(_session_id_key)
      # Checks to see if a route allows fixation: 
      # r.match('/foo').to(:controller => 'foo').fixatable 
      if request.route.allow_fixation?
        request.cookies[_session_id_key] = request.params[_session_id_key]
      end
    end
    @request, @response, @status, @headers = request, response, status, headers
  end
  
  # Dispatch the action
  #
  # ==== Parameters
  # action<~to_s>:: An action to dispatch to
  #
  # ==== Returns
  # String:: The string sent to the logger for time spent
  # 
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
  
  attr_reader :request, :response, :headers
  attr_accessor :status
  
  # ==== Returns
  # Hash:: The parameters from the request object

  # DOC: Yehuda Katz FAILED
  def params()  request.params  end
    
  # ==== Returns
  # Merb::Cookies:: 
  #   A new Merb::Cookies instance representing the cookies that came in
  #   from the request object
  #
  # ==== Note
  # headers are passed into the cookie object so that you can do:
  #   cookies[:foo] = "bar"

  def cookies() @_cookies ||= ::Merb::Cookies.new(request.cookies, @headers)  end
    
  # ==== Returns
  # Hash:: The session that was extracted from the request object

  # DOC: Yehuda Katz FAILED
  def session() request.session end

  # ==== Returns
  # Hash:: The route that was extracted from the request object

  # DOC: Yehuda Katz FAILED
  def route()   request.route   end
end