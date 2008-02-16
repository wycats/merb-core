module Merb
  
  class Router
    # Cache procs for future reference in eval statement
    class CachedProc
      @@index = 0
      @@list = []
      
      attr_accessor :cache, :index

      # ==== Parameters
      # cache<Proc>:: The block of code to cache.
      def initialize(cache)
        @cache, @index = cache, CachedProc.register(self)
      end
      
      # ==== Returns
      # String:: The CachedProc object in a format embeddable within a string.
      def to_s
        "CachedProc[#{@index}].cache"
      end
      
      class << self

        # ==== Parameters
        # cached_code<CachedProc>:: The cached code to register.
        #
        # ==== Returns
        # Fixnum:: The index of the newly registered CachedProc.
        def register(cached_code)
          CachedProc[@@index] = cached_code
          @@index += 1
          @@index - 1
        end

        # Sets the cached code for a specific index.
        #
        # ==== Parameters
        # index<Fixnum>:: The index of the cached code to set.
        # code<CachedProc>:: The cached code to set.
        def []=(index, code) @@list[index] = code end

        # ==== Parameters
        # index<Fixnum>:: The index of the cached code to retrieve.
        #
        # ==== Returns
        # CachedProc:: The cached code at index.
        def [](index) @@list[index] end
      end
    end # CachedProc
  end
end