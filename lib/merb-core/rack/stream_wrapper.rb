module Merb
  module Rack

    class StreamWrapper
       def initialize(body)
         @body = body
       end
            
       def each(&callback)
         if Proc === @body
           @writer = lambda { |x| callback.call(x) }
           @body.call(self)
         elsif @body.is_a?(String)
           @body.each_line(&callback)
         else
           @body.each(&callback)
         end
       end
    
       def write(str)
         @writer.call str.to_s
         str
       end
       
       def to_s
         @body.to_s
       end
       
       def ==(other)
         @body == other
       end
       
       def method_missing(sym, *args, &blk)
         @body.send(sym, *args, &blk)
       end
       
       
    end   
  
  end
end  
