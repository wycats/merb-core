module Merb

  # Cookies are read and written through Merb::Controller#cookies. The cookies
  # you read are those received in request along with those that have been set
  # during the current request. The cookies you write will be sent out with the
  # response. Cookies are read by value (so you won't get the cookie object
  # itself back -- just the value it holds).
  #
  # == Writing
  #
  #   cookies[:user]  = "dave" # => Sets a simple session cookie
  #   cookies[:token] = { :value => user.token, :expires => Time.now + 2.weeks }
  #     # => Will set a cookie that expires in 2 weeks
  #
  # == Reading
  #
  #   cookies[:user] # => "dave"
  #   cookies.size   # => 2 (the number of cookies)
  #
  # == Deleting
  #
  #   cookies.delete(:user)
  #
  # == Options
  #
  # * +value+   - the cookie's value
  # * +path+    - the path for which this cookie applies.  Defaults to the root
  #               of the application.
  # * +expires+ - the time at which this cookie expires, as a +Time+ object.
  class Cookies

    def initialize(request_cookies, headers)
      @_cookies = request_cookies
      @_headers = headers
    end

    # Returns the value of the cookie by +name+ or nil if no such cookie
    # exists. You set new cookies using cookies[]=
    def [](name)
      @_cookies[name]
    end

    # Sets the value of a cookie. You can set the value directly or pass a hash
    # with options.
    #
    # == Example
    #
    #   cookies[:user]  = "dave" # => Sets a simple session cookie
    #   cookies[:token] = { :value => user.token, :expires => Time.now + 2.weeks }
    #     # => Will set a cookie that expires in 2 weeks
    #
    # == Options
    #
    # * +value+   - the cookie's value or list of values (as an array).
    # * +path+    - the path for which this cookie applies.  Defaults to the root
    #               '/' of the application.
    # * +expires+ - the time at which this cookie expires, as a +Time+ object.
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

    # Removes the cookie on the client machine by setting the value to an empty string
    # and setting its expiration date into the past.
    def delete(name, options = {})
      cookie = @_cookies.delete(name)
      options = Mash.new(options)
      options[:expires] = Time.at(0)
      set_cookie(name, "", options)
      Merb.logger.info("Cookie deleted: #{name} => #{cookie.inspect}")
      cookie
    end

    private

      def set_cookie(name, value, options)
        options[:path] = '/' unless options[:path]
        if expiry = options[:expires]
          options[:expires] = expiry.gmtime.strftime(Merb::Const::COOKIE_EXPIRATION_FORMAT)
        end
        # options are sorted for testing purposes
        (@_headers['Set-Cookie'] ||=[]) << "#{name}=#{value}; " +
          options.map{|k, v| "#{k}=#{v};"}.sort.join(' ')
      end
  end
end