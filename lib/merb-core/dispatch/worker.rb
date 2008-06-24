module Merb
  class Worker
    
    attr_accessor :thread
    
    def initialize
      @thread = Thread.new { loop { process_queue } }
    end
    
    def process_queue
      while blk = Merb::Dispatcher.work_queue.pop
         # we've been blocking on the queue waiting for an item sleeping.
         # when someone pushes an item it wakes up this thread so we 
         # immediately pass execution to the scheduler so we don't 
         # accidentally run this block before the action finishes 
         # it's own processing
        Thread.pass
        blk.call
      end  
    end
    
  end
end    