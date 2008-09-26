10.times do
  Kernel.fork { GC.start; sleep 1000 }
end

sleep 1000