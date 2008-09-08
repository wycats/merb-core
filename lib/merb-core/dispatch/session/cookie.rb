require 'base64'        # to convert Marshal.dump to ASCII
require 'openssl'       # to generate the HMAC message digest
# Most of this code is taken from bitsweat's implementation in rails
module Merb

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
  class CookieSession < SessionContainer
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

    attr_accessor :_original_session_data

    # The session store type
    self.session_store_type = :cookie

    class << self
      # Generates a new session ID and creates a new session.
      #
      # ==== Returns
      # SessionContainer:: The new session.
      def generate
        self.new(Merb::SessionMixin.rand_uuid, "", Merb::Request._session_secret_key)
      end

      # Setup a new session.
      #
      # ==== Parameters
      # request<Merb::Request>:: The Merb::Request that came in from Rack.
      #
      # ==== Returns
      # SessionContainer:: a SessionContainer. If no sessions were found,
      # a new SessionContainer will be generated.
      def setup(request)
        session = self.new(Merb::SessionMixin.rand_uuid,
          request.session_cookie_value, request._session_secret_key)
        session._original_session_data = session.to_cookie
        request.session = session
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
      if secret.blank? || secret.length < 16
        Merb.logger.warn("You must specify a session_secret_key in your init file, and it must be at least 16 characters")
        raise ArgumentError, 'A secret is required to generate an integrity hash for cookie session data.'
      end
      @secret = secret
      self.update(unmarshal(cookie))
    end

    # Teardown and/or persist the current session.
    #
    # ==== Parameters
    # request<Merb::Request>:: The Merb::Request that came in from Rack.
    def finalize(request)
      if _original_session_data != (new_session_data = self.to_cookie)
        request.set_session_cookie_value(new_session_data)
      end
    end

    # Create the raw cookie string; includes an HMAC keyed message digest.
    #
    # ==== Returns
    # String:: Cookie value.
    #
    # ==== Raises
    # CookieOverflow:: Session contains too much information.
    #
    # ==== Notes
    # The data (self) is converted to a Hash first, since a container might
    # choose to do a full Marshal on the data, which would make it persist
    # attributes like 'needs_new_cookie', which it shouldn't.
    def to_cookie
      unless self.empty?
        data = self.serialize
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
      if cookie.blank?
        {}
      else
        data, digest = Merb::Request.unescape(cookie).split('--')
        return {} if data.blank? || digest.blank?
        unless digest == generate_digest(data)
          clear
          unless Merb::Config[:ignore_tampered_cookies]
            raise TamperedWithCookie, "Maybe the site's session_secret_key has changed?"
          end
        end
        unserialize(data)
      end
    end

    protected

    # Serialize current session data - as a Hash
    def serialize
      Base64.encode64(Marshal.dump(self.to_hash)).chop
    end

    # Unserialize the raw cookie data - to a Hash
    def unserialize(data)
      Marshal.load(Base64.decode64(data)) rescue {}
    end
  end
end
