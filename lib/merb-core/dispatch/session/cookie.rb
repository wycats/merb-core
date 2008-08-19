require 'base64'        # to convert Marshal.dump to ASCII
require 'openssl'       # to generate the HMAC message digest
# Most of this code is taken from bitsweat's implementation in rails
module Merb

  module SessionMixin

    # Adds a before and after dispatch hook for setting up the cookie session
    # store.
    #
    # ==== Parameters
    # base<Class>:: The class to which the SessionMixin is mixed into.
    def setup_session
      # request.session = Merb::CookieSession.new(cookies[_session_id_key], _session_secret_key)
      # @original_session = request.session.to_cookie
      
      Merb::CookieSession.setup(request)
    end

    # Finalizes the session by storing the session in a cookie, if the session
    # has changed.
    def finalize_session
      new_session_data = request.session.to_cookie
      if @original_session_data != new_session_data  
        options = {:expires => (Time.now + _session_expiry)}
        options[:domain] = _session_cookie_domain if _session_cookie_domain
        cookies.set_cookie(Merb::Config[:session_id_key], new_session_data, options)
      end
    end

    # ==== Returns
    # String:: The session store type, i.e. "cookie".
    def session_store_type
      "cookie"
    end
  end
  
  # If you have more than 4K of session data or don't want your data to be
  # visible to the user, pick another session store.
  #
  # CookieOverflow is raised if you attempt to store more than 4K of data.
  # TamperedWithCookie is raised if the data integrity check fails.
  #
  # A message digest is included with the cookie to ensure data integrity:
  # a user cannot alter session data without knowing the secret key included
  # in the hash. 
  # 
  # To use Cookie Sessions, set in config/merb.yml
  #  :session_secret_key - your secret digest key
  #  :session_store: cookie
  class CookieSession < SessionStore
    # TODO (maybe):
    # include request ip address
    # AES encrypt marshaled data
    
    # Raised when storing more than 4K of session data.
    class CookieOverflow < StandardError; end
    
    # Raised when the cookie fails its integrity check.
    class TamperedWithCookie < StandardError; end
    
    # Cookies can typically store 4096 bytes.
    MAX = 4096
    DIGEST = OpenSSL::Digest::Digest.new('SHA1') # or MD5, RIPEMD160, SHA256?
    
    class << self

      # Generates a new session ID and creates a new session.
      #
      # ==== Returns
      # SessionStore:: The new session.
      def generate
        Merb::CookieSession.new(Merb::SessionMixin::rand_uuid, "", Merb::Config[:session_secret_key])
      end

      # ==== Parameters
      # request<Merb::Request>:: The Merb::Request that came in from Rack.
      #
      # ==== Returns
      # SessionStore:: a SessionStore. If no sessions were found, 
      # a new SessionStore will be generated.
      def setup(request)
        request.session = Merb::CookieSession.new(Merb::SessionMixin::rand_uuid, request.session_cookie_value, Merb::Config[:session_secret_key])
        @original_session = request.session.to_cookie
        request.session
      end

      # ==== Returns
      # String:: The session store type, i.e. "memory".
      def session_store_type 
        "cookie"
      end

    end
    
    # ==== Parameters
    # session_id<String>:: A unique identifier for this session.
    # cookie<String>:: The raw cookie data.
    # secret<String>:: A session secret.
    #
    # ==== Raises
    # ArgumentError:: Nil or blank secret.
    def initialize(session_id, cookie, secret)
      super session_id
      if secret.nil? || secret.blank?
        raise ArgumentError, 'A secret is required to generate an integrity hash for cookie session data.'
      end
      @secret = secret
      self.update(cookie.blank? ? Hash.new : unmarshal(cookie))
    end
    
    # Create the raw cookie string; includes an HMAC keyed message digest.
    #
    # ==== Returns
    # String:: Cookie value.
    #
    # ==== Raises
    # CookieOverflow:: Session contains too much information.
    def to_cookie
      unless self.empty?
        data = Base64.encode64(Marshal.dump(self)).chop
        value = Merb::Request.escape "#{data}--#{generate_digest(data)}"
        raise CookieOverflow if value.size > MAX
        value
      end
    end
    
    private
    
    # Generate the HMAC keyed message digest. Uses SHA1.
    def generate_digest(data)
      OpenSSL::HMAC.hexdigest(DIGEST, @secret, data)
    end
    
    # Unmarshal cookie data to a hash and verify its integrity.
    #
    # ==== Parameters
    # cookie<~to_s>:: The cookie to unmarshal.
    #
    # ==== Raises
    # TamperedWithCookie:: The digests don't match.
    #
    # ==== Returns
    # Hash:: The stored session data.
    def unmarshal(cookie)
      if cookie
        data, digest = cookie.split('--')
        return {} if data.blank? || digest.blank?
        unless digest == generate_digest(data)
          clear
          raise TamperedWithCookie, "Maybe the site's session_secret_key has changed?"
        end
        Marshal.load(Base64.decode64(data))
      end
    end
    
  end
end