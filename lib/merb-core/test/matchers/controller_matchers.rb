module Merb::Test::Rspec::ControllerMatchers
  
  class BeRedirect
    def matches?(target)
      @target = target
      [307, *(300..305)].include?(target.respond_to?(:status) ? target.status : target)
    end
    def failure_message
      "expected#{inspect_target} to redirect"
    end
    def negative_failure_message
      "expected#{inspect_target} not to redirect"
    end
    
    def inspect_target
      " #{@target.controller_name}##{@target.action_name}" if @target.respond_to?(:controller_name) && @target.respond_to?(:action_name)
    end
  end
  
  class RedirectTo
    def initialize(expected)
      @expected = expected
    end
    
    def matches?(target)
      @target, @location = target, target.headers['Location']
      @redirected = BeRedirect.new.matches?(target.status)
      @location == @expected && @redirected
    end
    
    def failure_message
      msg = "expected #{inspect_target} to redirect to <#{@expected}>, but "
      if @redirected
        msg << "was <#{target_location}>" 
      else
        msg << "there was no redirection"
      end
    end
    
    def negative_failure_message
      "expected #{inspect_target} not to redirect to <#{@expected}>, but did anyway"
    end
    
    def inspect_target
      "#{@target.controller_name}##{@target.action_name}"
    end
    
    def target_location
      @target.respond_to?(:headers) ? @target.headers['Location'] : @target
    end
  end
  
  class BeSuccess
    
    def matches?(target)
      @target = target
      (200..207).include?(status_code)
    end
    
    def failure_message
      "expected#{inspect_target} to be successful but was #{status_code}"
    end
    
    def negative_failure_message
      "expected#{inspect_target} not to be successful but it was #{status_code}"
    end
    
    def inspect_target
      " #{@target.controller_name}##{@target.action_name}" if @target.respond_to?(:controller_name) && @target.respond_to?(:action_name)
    end
    
    def status_code
      @target.respond_to?(:status) ? @target.status : @target
    end
  end
  
  class BeMissing
    def matches?(target)
      @target = target
      (400..417).include?(status_code)
    end
    
    def failure_message
      "expected#{inspect_target} to be missing but was #{status_code}"
    end
    
    def negative_failure_message
      "expected#{inspect_target} not to be missing but it was #{status_code}"
    end
    
    def inspect_target
      " #{@target.controller_name}##{@target.action_name}" if @target.respond_to?(:controller_name) && @target.respond_to?(:action_name)
    end
    
    def status_code
      @target.respond_to?(:status) ? @target.status : @target
    end
  end
  
  # Passes if the target was redirected, or the target is a redirection (300 level) response code.
  #
  # ==== Example
  #   # Passes if the controller was redirected
  #   controller.should redirect
  #   
  #   # Also works if the target is the response code
  #   controller.status.should redirect
  #
  # ==== Note
  # valid HTTP Redirection codes:
  # * 300: Multiple Choices
  # * 301: Moved Permanently
  # * 302: Moved Temporarily (HTTP/1.0)
  # * 302: Found (HTTP/1.1)
  # * 303: See Other (HTTP/1.1)
  # * 304: Not Modified
  # * 305: Use Proxy
  # * 307: Temporary Redirect
  #--
  # status codes based on: http://cheat.errtheblog.com/s/http_status_codes/
  def redirect
    BeRedirect.new
  end
  
  alias_method :be_redirection, :redirect
  
  # Passes if the target was redirected to the expected location.
  #
  # ==== Paramters
  # expected<String>::
  #   A relative or absolute url.
  # ==== Example
  #   # Passes if the controller was redirected to http://example.com/
  #   controller.should redirect_to('http://example.com/')
  #
  def redirect_to(expected)
    RedirectTo.new(expected)
  end
  
  alias_method :be_redirection_to, :redirect_to
  
  # Passes if the request that generated the target was successful,
  # or the target is a success (200 level) response code.
  #
  # ==== Example
  #   # Passes if the controller call was successful
  #   controller.should respond_successfully
  #   
  #   # Also works if the target is the response code
  #   controller.status.should respond_successfully
  #
  # ==== Note
  # valid HTTP Success codes:
  # * 200: OK
  # * 201: Created
  # * 202: Accepted
  # * 203: Non-Authoritative Information
  # * 204: No Content
  # * 205: Reset Content
  # * 206: Partial Content
  # * 207: Multi-Status
  #--
  # status codes based on: http://cheat.errtheblog.com/s/http_status_codes/
  def respond_successfully
    BeSuccess.new
  end
  
  alias_method :be_successful, :respond_successfully
  
  # Passes if the request that generated the target was missing,
  # or the target is a client-side error (400 level) response code.
  #
  # ==== Example
  #   # Passes if the controller call was unknown or not understood
  #   controller.should be_missing
  #   
  #   # Also passes if the target is a response code
  #   controller.status.should be_missing
  #
  # ==== Note
  # valid HTTP Client Error codes:
  # * 400: Bad Request
  # * 401: Unauthorized
  # * 402: Payment Required
  # * 403: Forbidden
  # * 404: Not Found
  # * 405: Method Not Allowed
  # * 406: Not Acceptable
  # * 407: Proxy Authentication Required
  # * 408: Request Timeout
  # * 409: Conflict
  # * 410: Gone
  # * 411: Length Required
  # * 412: Precondition Failed
  # * 413: Request Entity Too Large
  # * 414: Request-URI Too Long
  # * 415: Unsupported Media Type
  # * 416: Requested Range Not Satisfiable
  # * 417: Expectation Failed
  # * 422: Unprocessable Entity
  #--
  # status codes based on: http://cheat.errtheblog.com/s/http_status_codes/
  def be_missing
    BeMissing.new
  end
  
  alias_method :be_client_error, :be_missing
end