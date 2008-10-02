module Merb
  module Rack

    class StreamWrapper
       def initialize(body)
         @body = body
       end
            
       def each(&callback)
         if @body.respond_to?(:call)
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
       
    end   
  
  end
end  
