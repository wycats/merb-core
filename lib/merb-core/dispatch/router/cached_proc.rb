

# DOC: Ezra Zygmuntowicz FAILED
module Merb
  
  # DOC: Ezra Zygmuntowicz FAILED
  class Router
    # Cache procs for future reference in eval statement

    # DOC: Ezra Zygmuntowicz FAILED
    class CachedProc
      @@index = 0
      @@list = []
      
      attr_accessor :cache, :index

      # DOC: Ezra Zygmuntowicz FAILED
      def initialize(cache)
        @cache, @index = cache, CachedProc.register(self)
      end
      
      # Make each CachedProc object embeddable within a string

      # DOC: Ezra Zygmuntowicz FAILED
      def to_s
        "CachedProc[#{@index}].cache"
      end
      
      class << self

        # DOC: Ezra Zygmuntowicz FAILED
        def register(cached_code)
          CachedProc[@@index] = cached_code
          @@index += 1
          @@index - 1
        end

        # DOC: Ezra Zygmuntowicz FAILED
        def []=(index, code) @@list[index] = code end

        # DOC: Ezra Zygmuntowicz FAILED
        def [](index) @@list[index] end
      end
    end # CachedProc
  end
end    