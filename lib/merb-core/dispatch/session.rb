

# DOC: Ezra Zygmuntowicz FAILED
module Merb
  
  # DOC: Ezra Zygmuntowicz FAILED
  module SessionMixin

    # DOC: Ezra Zygmuntowicz FAILED
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

    # DOC: Ezra Zygmuntowicz FAILED
    def needs_new_cookie!
      @_new_cookie = true
    end
    
    module_function :rand_uuid, :needs_new_cookie!
  end

end