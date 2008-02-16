module Merb
  
  module SessionMixin

    # ==== Returns
    # String:: A random 32 character string for use as a unique session ID.
    def rand_uuid
      values = [
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x1000000),
        rand(0x1000000),
      ]
      "%04x%04x%04x%04x%04x%06x%06x" % values
    end

    # Marks this session as needing a new cookie.
    def needs_new_cookie!
      @_new_cookie = true
    end
    
    module_function :rand_uuid, :needs_new_cookie!
  end

end