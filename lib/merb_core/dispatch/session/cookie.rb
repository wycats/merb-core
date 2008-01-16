require 'base64'        # to convert Marshal.dump to ASCII
require 'openssl'       # to generate the HMAC message digest

# Most of this code is taken from bitsweat's implementation in rails

module Merb
  
  module SessionMixin #:nodoc:
    def setup_session
      Merb.logger.info("Setting Up Cookie Store Sessions")
      request.session = Merb::CookieSession.new(cookies[_session_id_key], session_secret_key)
      @original_session = request.session.read_cookie
    end
    
    def finalize_session
      Merb.logger.info("Finalize Cookie Store Session")
      new_session = request.session.read_cookie

      if @original_session != new_session
        set_cookie(_session_id_key, new_session, _session_expiry) 
      end
    end
    
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
    
    def initialize(cookie, secret)
      if secret.nil? or secret.blank?
        raise ArgumentError, 'A secret is required to generate an integrity hash for cookie session data.'
      end
      @secret = secret
      @data = unmarshal(cookie) || Hash.new
    end
    
    # return a cookie value. raises CookieOverflow if session contains too
    # much information
    def read_cookie
      unless @data.nil? or @data.empty? 
        updated = marshal(@data)
        raise CookieOverflow if updated.size > MAX
        updated
      end
    end
    
    # assigns a key value pair 
    def []=(k, v) 
      @data[k] = v
    end
    
    def [](k) 
      @data[k] 
    end 
     
    def each(&b) 
      @data.each(&b) 
    end
    
    private
    
    def method_missing(name, *args, &block)
      @data.send(name, *args, &block)
    end
    
    # Generate the HMAC keyed message digest. Uses SHA1.
    def generate_digest(data)
      OpenSSL::HMAC.hexdigest(DIGEST, @secret, data)
    end
    
    # Marshal a session hash into safe cookie data. Include an integrity hash.
    def marshal(session)
      data = Base64.encode64(Marshal.dump(session)).chop
      Mongrel::HttpRequest.escape "#{data}--#{generate_digest(data)}"
    end
    
    # Unmarshal cookie data to a hash and verify its integrity.
    def unmarshal(cookie)
      if cookie
        data, digest = Mongrel::HttpRequest.unescape(cookie).split('--')
        unless digest == generate_digest(data)
          raise TamperedWithCookie, "Maybe the site's session_secret_key has changed?"
        end
        Marshal.load(Base64.decode64(data))
      end
    end
  end
end
