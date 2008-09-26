module Merb
  module Rack
    class AbstractAdapter
    
      def self.spawn_worker(port)
        pid = Kernel.fork
        start_at_port(port, @opts) unless pid

        # pid means we're in the parent, which means continue the loop
        throw(:new_worker) unless pid
        
        @pids[port] = pid
        $CHILDREN = @pids.values
      end
    
      def self.start(opts={})
        @opts = opts
        $CHILDREN ||= []
        parent = nil
        
        @pids = {}
        port = (opts[:socket] || opts[:port]).to_i
        max_port = Merb::Config[:cluster] ? Merb::Config[:cluster] - 1 : 0
        
        Merb.logger.warn! "Cluster: #{max_port}"
        
        if max_port == 0
          start_at_port(port)
          return
        end
        
        $0 = "merb: spawner"

        catch(:new_worker) do
          0.upto(max_port) do |i|
            parent = spawn_worker(port + i)
          end
        end

        # pid means we're in the parent, so start watching the children
        # no pid means we're in a child, so just move on
        return unless parent

        0.upto(max_port) do |i|
          Thread.new do
            catch(:new_worker) do
              loop do
                pid = @pids[port + i]
                begin
                  _, status = Process.wait2(pid)
                rescue SystemCallError => e
                ensure
                  Thread.exit if !status || status.exitstatus != 0 || Merb.exiting
                end
              
                spawn_worker(port + i)
              end
            end
          end
        end

        sleep
        
      end
      
      def self.start_at_port(port, opts = @opts)
        at_exit do
          Merb::Server.remove_pid(port)
        end
        
        if Merb::Config[:daemonize]
          trap('INT') do
            stop
            Merb.logger.warn! "Exiting port #{port}\n"
            exit_process
          end
        elsif Merb::Config[:fork_for_class_load]
          trap('INT') { 1 }
        end
        
        trap('HUP') do
          stop
          Merb.logger.warn! "Exiting port #{port} on #{Process.pid}\n"
          exit_process
        end
        
        trap('ABRT') do
          stopped = stop(128)
          Merb.logger.warn! "Exiting port #{port}\n" if stopped
          exit_process(128)
        end
        
        $0 = "merb: worker (port #{port})"
        
        Merb::Server.store_pid(port)
        Merb.logger = Merb::Logger.new(Merb.log_file(port), Merb::Config[:log_level], Merb::Config[:log_delimiter], Merb::Config[:log_auto_flush])
        Merb.logger.warn!("Starting #{self.name.split("::").last} at port #{port}")
        
        printed_warning = false
        loop do
          begin
            new_server(port)
          rescue Errno::EADDRINUSE
            unless printed_warning
              Merb.logger.warn! "Couldn't bind to port #{port}."
              Merb.logger.warn! "Waiting for it to become available"
              printed_warning = true
            end
            
            sleep 0.25
            next
          end
          break
        end

        Merb.logger.warn! "Successfully bound to port #{port}"
        
        Merb::Server.change_privilege
        
        start_server
      end
      
      def self.exit_process(status = 0)
        exit(status)
      end
      
    end
  end
end