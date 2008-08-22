module Merb

  # Cookies are read and written through Merb::Controller#cookies. The cookies
  # you read are those received in request along with those that have been set
  # during the current request. The cookies you write will be sent out with the
  # response. Cookies are read by value (so you won't get the cookie object
  # itself back -- just the value it holds).
  class Cookies

    # ==== Parameters
    # request_cookies<Hash>:: Initial cookie store.
    # headers<Hash>:: The response headers.
    # default_domain<String>:: The default cookie domain.
    def initialize(request_cookies, headers, default_domain = nil)
      @_cookies = request_cookies
      @_headers = headers
      @_default_domain = default_domain
    end

    # ==== Parameters
    # name<~to_s>:: Name of the cookie.
    #
    # ==== Returns
    # String:: Value of the cookie.
    def [](name)
      @_cookies[name]
    end

    # ==== Parameters
    # name<~to_s>:: Name of the cookie.
    # options<Hash, ~to_s>:: Options for the cookie being set (see below).
    #
    # ==== Options (options)
    # :value<~to_s>:: Value of the cookie
    # :path<String>:: The path for which this cookie applies. Defaults to "/".
    # :expires<Time>:: Cookie expiry date.
    # :domain<String>:: The domain for which this cookie applies.
    # :secure<Boolean>:: Security flag.
    #
    # ==== Alternatives
    # If options is not a hash, it will be used as the cookie value directly.
    #
    # ==== Examples
    #   cookies[:user] = "dave" # => Sets a simple session cookie
    #   cookies[:token] = { :value => user.token, :expires => Time.now + 2.weeks }
    #     # => Will set a cookie that expires in 2 weeks
    def []=(name, options)
      value = ''
      if options.is_a?(Hash)
        options = Mash.new(options)
        value = options.delete(:value)
      else
        value = options
        options = Mash.new
      end
      @_cookies[name] = value
      set_cookie(name, Merb::Request.escape(value), options)
      Merb.logger.info("Cookie set: #{name} => #{value} -- #{options.inspect}")
      options
    end

    # Removes the cookie on the client machine by setting the value to an empty
    # string and setting its expiration date into the past.
    #
    # ==== Parameters
    # name<~to_s>:: Name of the cookie to delete.
    # options<Hash>:: Additional options to pass to +set_cookie+.
    def delete(name, options = {})
      cookie = @_cookies.delete(name)
      options = Mash.new(options)
      options[:expires] = Time.at(0)

      set_cookie(name, "", options)
      Merb.logger.info("Cookie deleted: #{name} => #{cookie.inspect}")
      cookie
    end
    
    # ==== Parameters
    # name<~to_s>:: Name of the cookie.
    # value<~to_s>:: Value of the cookie.
    # options<Hash>:: Additional options for the cookie (see below).
    #
    # ==== Options (options)
    # :path<String>:: The path for which this cookie applies. Defaults to "/".
    # :expires<Time>:: Cookie expiry date.
    # :domain<String>:: The domain for which this cookie applies.
    # :secure<Boolean>:: Security flag.
    def set_cookie(name, value, options)
      options[:path] = '/' unless options[:path]
      if expiry = options[:expires]
        options[:expires] = expiry.gmtime.strftime(Merb::Const::COOKIE_EXPIRATION_FORMAT)
      end
      
      if domain = options[:domain] || @_default_domain
        options[:domain] = domain
      end

      secure = options.delete(:secure)
      
      @_headers['Set-Cookie'] ||=[]
      
      kookie = "#{name}=#{value}; "
      # options are sorted for testing purposes:
      # Hash is unsorted so string is spec is random every run
      kookie <<  options.map{|k, v| "#{k}=#{v};"}.join(' ')
      kookie << ' secure' if secure
      
      @_headers['Set-Cookie'] << kookie
    end
  end
  
  module CookiesMixin
    
    def self.included(base)
      # Allow per-controller default cookie domains (see callback below)
      base.class_inheritable_accessor :_default_cookie_domain
      base._default_cookie_domain = Merb::Config[:default_cookie_domain]
      
      # Add a callback to enable Set-Cookie headers
      base._after_dispatch_callbacks << lambda do |c|
        headers = c.request.cookies.to_headers(:domain => c._default_cookie_domain)
        c.headers.update(headers)
      end
    end
    
    # ==== Returns
    # Merb::Cookies::
    #   A new Merb::Cookies instance representing the cookies that came in
    #   from the request object
    #
    # ==== Notes
    # Headers are passed into the cookie object so that you can do:
    #   cookies[:foo] = "bar"
    def cookies
      request.cookies
    end
    
    module RequestMixin
      
      class NewCookies < Mash
      
        def initialize(constructor = {}, cookie_defaults = {})
          @_options_lookup = {}
          @_cookie_defaults = cookie_defaults
          super constructor
        end
        
        # ==== Parameters
        # name<~to_s>:: Name of the cookie.
        # value<~to_s>:: Value of the cookie.
        # options<Hash>:: Additional options for the cookie (see below).
        #
        # ==== Options (options)
        # :path<String>:: The path for which this cookie applies. Defaults to "/".
        # :expires<Time>:: Cookie expiry date.
        # :domain<String>:: The domain for which this cookie applies.
        # :secure<Boolean>:: Security flag.
        def set_cookie(name, value, options = {})
          Merb.logger.info("Cookie set: #{name} => #{value} -- #{options.inspect}")
          @_options_lookup[name] = options unless options.blank?
          self[name] = value
        end
        
        # Removes the cookie on the client machine by setting the value to an empty
        # string and setting its expiration date into the past.
        #
        # ==== Parameters
        # name<~to_s>:: Name of the cookie to delete.
        # options<Hash>:: Additional options to pass to +set_cookie+.
        def delete(name, options = {})
          Merb.logger.info("Cookie deleted: #{name} => #{options.inspect}")
          set_cookie(name, "", options.merge(:expires => Time.at(0)))
        end
        
        # Generate any necessary headers.
        #
        # ==== Returns
        # Hash:: The headers to set, or an empty array if no cookies are set.
        def to_headers(controller_defaults = {})
          defaults = @_cookie_defaults.merge(controller_defaults)
          cookies = []
          self.each do |name, value|
            options = defaults.merge(@_options_lookup[name] || {})
            secure  = options.delete(:secure)
            kookie  = "#{name}=#{Merb::Request.escape(value)}; "
            options.each { |k, v| kookie << "#{k}=#{v}; " }
            kookie  << 'secure' if secure
            cookies << kookie.rstrip
          end
          cookies.empty? ? {} : { 'Set-Cookie' => cookies }
        end
        
      end
            
      # ==== Returns
      # Hash:: The cookies for this request.
      #
      # ==== Notes
      # If a method #default_cookies is defined it will be called. This can
      # be used for session fixation purposes for example. The method returns
      # a Hash of key => value pairs.
      def cookies
        @cookies ||= begin
          values  = self.class.query_parse(@env[Merb::Const::HTTP_COOKIE], ';,')
          cookies = NewCookies.new(values, :domain => Merb::Controller._default_cookie_domain, :path => '/')
          cookies.update(default_cookies) if respond_to?(:default_cookies)
          cookies
        end
      end
      
    end   
    
  end
  
end
