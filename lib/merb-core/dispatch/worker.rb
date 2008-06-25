module Merb
  class Worker
    
    attr_accessor :thread
    
    def initialize
      @thread = Thread.new { loop { process_queue } }
    end
    
    def process_queue
      begin
        while blk = Merb::Dispatcher.work_queue.pop
           # we've been blocking on the queue waiting for an item sleeping.
           # when someone pushes an item it wakes up this thread so we 
           # immediately pass execution to the scheduler so we don't 
           # accidentally run this block before the action finishes 
           # it's own processing
          Thread.pass
          blk.call
        end
      rescue Exception => e
        Merb.logger.warn! %Q!Worker Thread Crashed with Exception:\n#{Merb.exception(e)}\nRestarting Worker Thread!
        retry
      end    
    end
    
  end
end    