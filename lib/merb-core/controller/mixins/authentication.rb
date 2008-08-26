module Merb::AuthenticationMixin
  
  # Attempts to authenticate the user via HTTP Basic authentication. Takes a
  # block with the username and password, if the block yields false the
  # authentication is not accepted and :halt is thrown.
  #
  # If no block is passed, +basic_authentication+, the +request+ and +authenticate+
  # methods can be chained. These can be used to independently request authentication
  # or confirm it, if more control is desired.
  #
  # ==== Parameters
  # realm<~to_s>:: The realm to authenticate against. Defaults to 'Application'.
  # &authenticator:: A block to check if the authentication is valid.
  #
  # ==== Examples
  #     class Application < Merb::Controller
  #     
  #       before :authenticate
  #     
  #       protected
  #     
  #       def authenticate
  #         basic_authentication("My App") do |username, password|
  #           password == "secret"
  #         end
  #       end
  #     
  #     end
  #
  #     class Application < Merb::Controller
  #     
  #       before :authenticate
  #     
  #       def authenticate
  #         user = basic_authentication.authenticate do |username, password|
  #           User.authenticate(username, password)
  #         end
  #     
  #         if user
  #           @current_user = user
  #         else
  #           basic_authentication.request
  #         end
  #       end
  #     
  #     end
  #
  # If you need to request basic authentication inside an action you need to use the request! method.
  #
  # ====Example
  #
  #    class Sessions < Application
  #  
  #      def new
  #        case content_type
  #        when :html
  #          render
  #        else
  #          basic_authentication.request!
  #        end
  #      end
  # 
  #    end 
  #
  #---
  # @public
  def basic_authentication(realm = "Application", &authenticator)
    @_basic_authentication ||= BasicAuthentication.new(self, realm, &authenticator)
  end
  
  class BasicAuthentication
    # So we can have access to the status codes
    include Merb::ControllerExceptions

    def initialize(controller, realm = "Application", &authenticator)
      @controller = controller
      @realm = realm
      @auth = Rack::Auth::Basic::Request.new(@controller.request.env)
      authenticate_or_request(&authenticator) if authenticator
    end

    def authenticate(&authenticator)
      if @auth.provided? and @auth.basic?
        authenticator.call(*@auth.credentials)
      else
        false
      end
    end

    def request
      request!
      throw :halt, @controller.render("HTTP Basic: Access denied.\n", :status => Unauthorized.status, :layout => false)
    end
    
    # This is a special case for use outside a before filter.  Use this if you need to 
    # request basic authenticaiton as part of an action
    def request!
      @controller.status = Unauthorized.status
      @controller.headers['WWW-Authenticate'] = 'Basic realm="%s"' % @realm
    end
    
    # Checks to see if there has been any basic authentication credentials provided
    def provided?
      @auth.provided?
    end
    
    def username
      provided? ? @auth.credentials.first : nil
    end
    
    def password
      provided? ? @auth.credentials.last : nil
    end
    
    protected
    
    def authenticate_or_request(&authenticator)
      authenticate(&authenticator) || request
    end
    
  end

end
