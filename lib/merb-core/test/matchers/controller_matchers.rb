module Merb::Test::Rspec::ControllerMatchers

  class BeRedirect
    # ==== Parameters
    # target<Fixnum, ~status>::
    #   Either the status code or a controller with a status code.
    #
    # ==== Returns
    # Boolean:: True if the status code is in the range 300..305 or 307.
    def matches?(target)
      @target = target
      [307, *(300..305)].include?(target.respond_to?(:status) ? target.status : target)
    end

    # ==== Returns
    # String:: The failure message.
    def failure_message
      "expected#{inspect_target} to redirect"
    end

    # ==== Returns
    # String:: The failure message to be displayed in negative matches.
    def negative_failure_message
      "expected#{inspect_target} not to redirect"
    end

    # ==== Returns
    # String:: The controller and action name.
    def inspect_target
      " #{@target.controller_name}##{@target.action_name}" if @target.respond_to?(:controller_name) && @target.respond_to?(:action_name)
    end
  end

  class RedirectTo

    # === Parameters
    # String:: The expected location
    # Hash:: Optional hash of options (currently only :message)
    def initialize(expected, options = {})
      @expected = expected
      @options  = options
    end

    # ==== Parameters
    # target<Merb::Controller>:: The controller to match
    #
    # ==== Returns
    # Boolean::
    #   True if the controller status is redirect and the locations match.
    def matches?(target)
      @target, @location = target, target.headers['Location']
      @redirected = BeRedirect.new.matches?(target.status)

      if @options[:message]
        msg = Merb::Request.escape([Marshal.dump(@options[:message])].pack("m"))
        @expected << "?_message=#{msg}"
      end
      
      @location == @expected && @redirected
    end

    # ==== Returns
    # String:: The failure message.
    def failure_message
      msg = "expected #{inspect_target} to redirect to <#{@expected}>, but "
      if @redirected
        msg << "was <#{target_location}>"
      else
        msg << "there was no redirection"
      end
    end

    # ==== Returns
    # String:: The failure message to be displayed in negative matches.
    def negative_failure_message
      "expected #{inspect_target} not to redirect to <#{@expected}>, but did anyway"
    end

    # ==== Returns
    # String:: The controller and action name.
    def inspect_target
      "#{@target.controller_name}##{@target.action_name}"
    end

    # ==== Returns
    # String:: Either the target's location header or the target itself.
    def target_location
      @target.respond_to?(:headers) ? @target.headers['Location'] : @target
    end
  end

  class BeSuccess

    # ==== Parameters
    # target<Fixnum, ~status>::
    #   Either the status code or a controller with a status code.
    #
    # ==== Returns
    # Boolean:: True if the status code is in the range 200..207.
    def matches?(target)
      @target = target
      (200..207).include?(status_code)
    end

    # ==== Returns
    # String:: The failure message.
    def failure_message
      "expected#{inspect_target} to be successful but was #{status_code}"
    end

    # ==== Returns
    # String:: The failure message to be displayed in negative matches.
    def negative_failure_message
      "expected#{inspect_target} not to be successful but it was #{status_code}"
    end

    # ==== Returns
    # String:: The controller and action name.
    def inspect_target
      " #{@target.controller_name}##{@target.action_name}" if @target.respond_to?(:controller_name) && @target.respond_to?(:action_name)
    end

    # ==== Returns
    # Fixnum:: Either the target's status or the target itself.
    def status_code
      @target.respond_to?(:status) ? @target.status : @target
    end
  end

  class BeMissing

    # ==== Parameters
    # target<Fixnum, ~status>::
    #   Either the status code or a controller with a status code.
    #
    # ==== Returns
    # Boolean:: True if the status code is in the range 400..417.
    def matches?(target)
      @target = target
      (400..417).include?(status_code)
    end

    # ==== Returns
    # String:: The failure message.
    def failure_message
      "expected#{inspect_target} to be missing but was #{status_code}"
    end

    # ==== Returns
    # String:: The failure message to be displayed in negative matches.
    def negative_failure_message
      "expected#{inspect_target} not to be missing but it was #{status_code}"
    end

    # ==== Returns
    # String:: The controller and action name.
    def inspect_target
      " #{@target.controller_name}##{@target.action_name}" if @target.respond_to?(:controller_name) && @target.respond_to?(:action_name)
    end

    # ==== Returns
    # Fixnum:: Either the target's status or the target itself.
    def status_code
      @target.respond_to?(:status) ? @target.status : @target
    end
  end

  class BeError
    def initialize(expected)
      @expected = expected
    end
    
    def matches?(target)
      @target = target
      @target.request.exceptions &&
        @target.request.exceptions.first.is_a?(@expected)
    end
    
    def failure_message
      "expected #{@target} to be a #{@expected} error, but it was " << 
        @target.request.exceptions.first.inspect
    end
    
    def negative_failure_message
      "expected #{@target} not to be a #{@expected} error, but it was"
    end
  end

  class Provide

    # === Parameters
    # expected<Symbol>:: A format to check
    def initialize(expected)
      @expected = expected
    end

    # ==== Parameters
    # target<Symbol>::
    #   A ControllerClass or controller_instance
    #
    # ==== Returns
    # Boolean:: True if the formats provided by the target controller/class include the expected
    def matches?(target)
      @target = target
      provided_formats.include?( @expected )
    end

    # ==== Returns
    # String:: The failure message.
    def failure_message
      "expected #{@target.name} to provide #{@expected}, but it doesn't"
    end

    # ==== Returns
    # String:: The failure message to be displayed in negative matches.
    def negative_failure_message
      "expected #{@target.name} not to provide #{@expected}, but it does"
    end

    # ==== Returns
    # Array[Symbol]:: The formats the expected provides
    def provided_formats
      @target.class_provided_formats
    end
  end

  # Passes if the target was redirected, or the target is a redirection (300
  # level) response code.
  #
  # ==== Examples
  #   # Passes if the controller was redirected
  #   controller.should redirect
  #
  #   # Also works if the target is the response code
  #   controller.status.should redirect
  #
  # ==== Notes
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
  # expected<String>:: A relative or absolute url.
  #
  # ==== Examples
  #   # Passes if the controller was redirected to http://example.com/
  #   controller.should redirect_to('http://example.com/')
  def redirect_to(expected, options = {})
    RedirectTo.new(expected, options)
  end

  alias_method :be_redirection_to, :redirect_to

  # Passes if the request that generated the target was successful, or the
  # target is a success (200 level) response code.
  #
  # ==== Examples
  #   # Passes if the controller call was successful
  #   controller.should respond_successfully
  #
  #   # Also works if the target is the response code
  #   controller.status.should respond_successfully
  #
  # ==== Notes
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

  # Passes if the request that generated the target was missing, or the target
  # is a client-side error (400 level) response code.
  #
  # ==== Examples
  #   # Passes if the controller call was unknown or not understood
  #   controller.should be_missing
  #
  #   # Also passes if the target is a response code
  #   controller.status.should be_missing
  #
  # ==== Notes
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
  
  def be_error(expected)
    BeError.new(expected)
  end

  alias_method :be_client_error, :be_missing

  # Passes if the controller actually provides the target format
  #
  # === Parameters
  # expected<Symbol>:: A format to check
  #
  # ==== Examples
  #   ControllerClass.should provide( :html )
  #   controller_instance.should provide( :xml )
  def provide( expected )
    Provide.new( expected )
  end
end
