require 'base64'        # to convert Marshal.dump to ASCII
require 'openssl'       # to generate the HMAC message digest

# Most of this code is taken from bitsweat's implementation in rails

# DOC: Ezra Zygmuntowicz FAILED
module Merb

  # DOC: Ezra Zygmuntowicz FAILED
  module SessionMixin #:nodoc:

    # DOC: Ezra Zygmuntowicz FAILED
    def self.included(base)
      base.add_hook :before_dispatch do
        Merb.logger.info("Setting Up Cookie Store Sessions")
        request.session = Merb::CookieSession.new(cookies[_session_id_key], _session_secret_key)
        @original_session = request.session.read_cookie
      end

      base.add_hook :after_dispatch do
        Merb.logger.info("Finalize Cookie Store Session")
        new_session = request.session.read_cookie
      
        if @original_session != new_session
          set_cookie(_session_id_key, new_session, Time.now + _session_expiry) 
        end
      end
    end

    # DOC: Ezra Zygmuntowicz FAILED
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

    # DOC: Ezra Zygmuntowicz FAILED
    class TamperedWithCookie < StandardError; end
    
    # Cookies can typically store 4096 bytes.
    MAX = 4096
    DIGEST = OpenSSL::Digest::Digest.new('SHA1') # or MD5, RIPEMD160, SHA256?
    
    attr_reader :data

    # DOC: Ezra Zygmuntowicz FAILED
    def initialize(cookie, secret)
      if secret.nil? or secret.blank?
        raise ArgumentError, 'A secret is required to generate an integrity hash for cookie session data.'
      end
      @secret = secret
      @data = unmarshal(cookie) || Hash.new
    end
    
    # return a cookie value. raises CookieOverflow if session contains too
    # much information

    # DOC: Ezra Zygmuntowicz FAILED
    def read_cookie
      unless @data.nil? or @data.empty? 
        updated = marshal(@data)
        raise CookieOverflow if updated.size > MAX
        updated
      end
    end
    
    # assigns a key value pair

    # DOC: Ezra Zygmuntowicz FAILED
    def []=(k, v) 
      @data[k] = v
    end

    # DOC: Ezra Zygmuntowicz FAILED
    def [](k) 
      @data[k] 
    end

    # DOC: Ezra Zygmuntowicz FAILED
    def each(&b) 
      @data.each(&b) 
    end
    
    def delete  
      @data = {} 
    end
    
    private

    # DOC: Ezra Zygmuntowicz FAILED
    def method_missing(name, *args, &block)
      @data.send(name, *args, &block)
    end
    
    # Generate the HMAC keyed message digest. Uses SHA1.

    # DOC: Ezra Zygmuntowicz FAILED
    def generate_digest(data)
      OpenSSL::HMAC.hexdigest(DIGEST, @secret, data)
    end
    
    # Marshal a session hash into safe cookie data. Include an integrity hash.

    # DOC: Ezra Zygmuntowicz FAILED
    def marshal(session)
      data = Base64.encode64(Marshal.dump(session)).chop
      Merb::Request.escape "#{data}--#{generate_digest(data)}"
    end
    
    # Unmarshal cookie data to a hash and verify its integrity.

    # DOC: Ezra Zygmuntowicz FAILED
    def unmarshal(cookie)
      if cookie
        data, digest = Merb::Request.unescape(cookie).split('--')
        unless digest == generate_digest(data)
          raise TamperedWithCookie, "Maybe the site's session_secret_key has changed?"
        end
        Marshal.load(Base64.decode64(data))
      end
    end
  end
end