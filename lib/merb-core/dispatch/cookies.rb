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
    def initialize(request_cookies, headers)
      @_cookies = request_cookies
      @_headers = headers
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

    private
    # ==== Parameters
    # name<~to_s>:: Name of the cookie.
    # value<~to_s>:: Value of the cookie.
    # options<Hash>:: Additional options for the cookie (see below).
    #
    # ==== Options (options)
    # :path<String>:: The path for which this cookie applies. Defaults to "/".
    # :expires<Time>:: Cookie expiry date.
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