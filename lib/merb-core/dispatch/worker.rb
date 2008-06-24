module Merb
  class Worker
    
    attr_accessor :thread
    
    def initialize
      @thread = Thread.new { loop { process_queue } }
    end
    
    def process_queue
      while blk = Merb::Dispatcher.work_queue.pop
        blk.call
      end  
    end
    
  end
end    