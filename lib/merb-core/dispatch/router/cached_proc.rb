module Merb
  
  class Router
    # Cache procs for future reference in eval statement
    class CachedProc
      @@index = 0
      @@list = []
      
      attr_accessor :cache, :index

      def initialize(cache)
        @cache, @index = cache, CachedProc.register(self)
      end
      
      # Make each CachedProc object embeddable within a string
      def to_s
        "CachedProc[#{@index}].cache"
      end
      
      class << self
        def register(cached_code)
          CachedProc[@@index] = cached_code
          @@index += 1
          @@index - 1
        end

        def []=(index, code) @@list[index] = code end

        def [](index) @@list[index] end
      end
    end # CachedProc
  end
end    