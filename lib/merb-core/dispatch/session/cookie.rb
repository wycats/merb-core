require 'base64'        # to convert Marshal.dump to ASCII
require 'openssl'       # to generate the HMAC message digest
# Most of this code is taken from bitsweat's implementation in rails
module Merb

  module SessionMixin #:nodoc:

    # Adds a before and after dispatch hook for setting up the cookie session
    # store.
    #
    # ==== Parameters
    # base<Class>:: The class to which the SessionMixin is mixed into.
    def setup_session
      request.session = Merb::CookieSession.new(cookies[_session_id_key], _session_secret_key)
      @original_session = request.session.read_cookie
    end

    # Finalizes the session by storing the session in a cookie, if the session
    # has changed.
    def finalize_session
      new_session = request.session.read_cookie
      
      if @original_session != new_session
        set_cookie(_session_id_key, new_session, Time.now + _session_expiry) 
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
  class CookieSession
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
    
    attr_reader :data

    # ==== Parameters
    # cookie<String>:: The cookie.
    # secret<String>:: A session secret.
    #
    # ==== Raises
    # ArgumentError:: Nil or blank secret.
    def initialize(cookie, secret)
      if secret.nil? or secret.blank?
        raise ArgumentError, 'A secret is required to generate an integrity hash for cookie session data.'
      end
      @secret = secret
      @data = unmarshal(cookie) || Hash.new
    end
    
    # ==== Returns
    # String:: Cookie value.
    #
    # ==== Raises
    # CookieOverflow:: Session contains too much information.
    def read_cookie
      unless @data.nil? or @data.empty? 
        updated = marshal(@data)
        raise CookieOverflow if updated.size > MAX
        updated
      end
    end
    
    # ==== Parameters
    # k<~to_s>:: The key of the session parameter to set.
    # v<~to_s>:: The value of the session parameter to set.
    def []=(k, v) 
      @data[k] = v
    end

    # ==== Parameters
    # k<~to_s>:: The key of the session parameter to retrieve.
    #
    # ==== Returns
    # String:: The value of the session parameter.
    def [](k) 
      @data[k] 
    end

    # Yields the session data to an each block.
    #
    # ==== Parameter
    # &b:: The block to pass to each.
    def each(&b) 
      @data.each(&b) 
    end

    # Deletes the session by emptying stored data.
    def delete  
      @data = {} 
    end
    
    private

    # Attempts to redirect any messages to the data object.
    def method_missing(name, *args, &block)
      @data.send(name, *args, &block)
    end
    
    # Generate the HMAC keyed message digest. Uses SHA1.
    def generate_digest(data)
      OpenSSL::HMAC.hexdigest(DIGEST, @secret, data)
    end
    
    # Marshal a session hash into safe cookie data. Include an integrity hash.
    #
    # ==== Parameters
    # session<Hash>:: The session to store in the cookie.
    #
    # ==== Returns
    # String:: The cookie to be stored.
    def marshal(session)
      data = Base64.encode64(Marshal.dump(session)).chop
      Merb::Request.escape "#{data}--#{generate_digest(data)}"
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
        data, digest = Merb::Request.unescape(cookie).split('--')
        return {} if data.blank?
        unless digest == generate_digest(data)
          raise TamperedWithCookie, "Maybe the site's session_secret_key has changed?"
        end
        Marshal.load(Base64.decode64(data))
      end
    end
  end
end