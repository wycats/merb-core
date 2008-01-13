class Merb::Controller < AbstractController
  
  class_inheritable_accessor :_session_id_key, :_session_expiry, :_hidden_actions
  cattr_accessor :_subclasses, :_session_secret_key
  self._subclasses = Set.new
  self.session_secret_key = nil
  self._session_id_key = '_session_id'
  self._session_expiry = Time.now + Merb::Const::WEEK * 2
  
  include Merb::ResponderMixin
  include Merb::ControllerExceptions
  
  class << self
    
    # ==== Parameters
    # klass<Merb::Controller>:: The Merb::Controller inheriting from the
    #                           base class
    def inherited(klass)
      _subclasses << klass.to_s
      klass._hidden_actions = Merb::Controller.public_instance_methods
      super
    end

    # A list of actions that should not be available as callable actions
    def hidden_actions
      _hidden_actions
    end
    
    # Hide each of the given methods from being callable as actions.
    #
    # ==== Parameters
    # *names<~to-s>:: Actions that should be added to the list 
    def hide_action(*names)
      _hidden_actions = _hidden_actions | names.collect { |n| n.to_s })
    end
    
    # Build a new controller.
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
    def build(request, response = StringIO.new, status=200, headers={'Content-Type' => 'text/html; charset=utf-8'})
      cont = new
      cont.set_dispatch_variables(request, response, status, headers)
      cont
    end
    
    # Sets the variables that came in through the dispatch as available to
    # the controller. This is called by .build, so see it for more
    # information.
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
    def set_dispatch_variables(request, response, status, headers)
      if request.params.key?(_session_id_key)
        if Merb::Config[:session_id_cookie_only]
          # This condition allows for certain controller/action paths to allow
          # a session ID to be passed in a query string. This is needed for
          # Flash Uploads to work since flash will not pass a Session Cookie
          # Recommend running session.regenerate after any controller taking
          # advantage of this in case someone is attempting a session fixation
          # attack
          if Merb::Config[:query_string_whitelist].include?("#{request.controller_name}/#{request.action}")
          # FIXME to use routes not controller and action names -----^
            request.cookies[_session_id_key] = request.params[_session_id_key]
          end
        else
          request.cookies[_session_id_key] = request.params[_session_id_key]
        end
      end
      @_request  = request
      @_response = response
      @_status   = status
      @_headers  = headers
    end
    
    # Dispatch the action
    #
    # ==== Parameters
    # action<~to_s>:: An action to dispatch to
    def dispatch(action=:index)
      start = Time.now
      if self.class.callable_actions[action.to_s]
        params[:action] ||= action
        setup_session
        super(action)
        finalize_session
      else
        raise ActionNotFound, "Action '#{action}' was not found in #{self.class}"
      end
      @_benchmarks[:action_time] = Time.now - start
      Merb.logger.info("Time spent in #{self.class}##{action} action: #{@_benchmarks[:action_time]} seconds")
    end
    
    _attr_reader :body, :status, :request, :params, :headers, :response
    def params()  request.params  end
    def cookies() request.cookies end
    def session() request.session end
    def route()   request.route   end
    
  end
end