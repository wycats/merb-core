module Merb
  module Rack
    class AbstractAdapter

      # Spawn a new worker process at a port.
      def self.spawn_worker(port)
        child_pid = Kernel.fork
        start_at_port(port, @opts) unless child_pid

        # If we have a child_pid, we're in the parent. If we're
        throw(:new_worker) unless child_pid

        @pids[port] = child_pid
        $CHILDREN = @pids.values
      end

      # The main start method for bootloaders that support forking.
      def self.start(opts={})
        @opts = opts
        $CHILDREN ||= []
        parent = nil

        @pids = {}
        port = (opts[:socket] || opts[:port]).to_i
        max_port = Merb::Config[:cluster] ? Merb::Config[:cluster] - 1 : 0

        Merb.logger.warn! "Cluster: #{max_port}"

        # If we only have a single merb, just start it up and dispense with
        # the spawner/worker setup.
        if max_port == 0
          start_at_port(port)
          return
        end

        $0 = process_title(:spawner, port)

        # For each port, spawn a new worker. The parent will continue in
        # the loop, while the child will throw :new_worker and be booted
        # out of the loop.
        catch(:new_worker) do
          0.upto(max_port) do |i|
            parent = spawn_worker(port + i)
          end
        end

        # If we're in a worker, we're done. Otherwise, we've completed
        # setting up workers and now need to watch them.
        return unless parent

        # For each worker, set up a thread in the spawner to watch it
        0.upto(max_port) do |i|
          Thread.new do
            catch(:new_worker) do
              loop do
                pid = @pids[port + i]
                begin
                  # Watch for the pid to exit.
                  _, status = Process.wait2(pid)

                  # If the pid doesn't exist, we want to silently exit instead of
                  # raising here.
                rescue SystemCallError => e
                ensure
                  # If there was no worker with that PID, the status was non-0
                  # (we send back a status of 128 when ABRT is called on a 
                  # child, and Merb.fatal! exits with a status of 1), or if
                  # Merb is in the process of exiting, *then* don't respawn.
                  # Note that processes killed with kill -9 will return no
                  # exitstatus, and we respawn them.
                  if !status || 
                    (status.exitstatus && status.exitstatus != 0) || 
                    Merb.exiting then
                    Thread.exit
                  end
                end

                # Otherwise, respawn the worker, and watch it again.
                spawn_worker(port + i)
              end
            end
          end
        end

        # The spawner process will make it here, and when it does, it should just 
        # sleep so it can pick up ctrl-c if it's in console mode.
        sleep

      end

      def self.start_at_port(port, opts = @opts)
        at_exit do
          Merb::Server.remove_pid(port)
        end

        # If Merb is daemonized, trap INT. If it's not daemonized,
        # we let the master process' ctrl-c control the cluster
        # of workers.
        if Merb::Config[:daemonize]
          trap('INT') do
            stop
            Merb.logger.warn! "Exiting port #{port}\n"
            exit_process
          end
          # If it was not fork_for_class_load, we already set up
          # ctrl-c handlers in the master thread.
        elsif Merb::Config[:fork_for_class_load]
          trap('INT') { 1 }
        end

        # In daemonized mode or not, support HUPing the process to
        # restart it.
        trap('HUP') do
          stop
          Merb.logger.warn! "Exiting port #{port} on #{Process.pid}\n"
          exit_process
        end

        # ABRTing the process will kill it, and it will not be respawned.
        trap('ABRT') do
          stopped = stop(128)
          Merb.logger.warn! "Exiting port #{port}\n" if stopped
          exit_process(128)
        end

        # Each worker gets its own `ps' name.
        $0 = process_title(:worker, port)

        # Store the PID for this worker
        Merb::Server.store_pid(port)

        Merb::Config[:log_delimiter] = "#{$0} ~ "

        Merb.logger = nil
        Merb.logger.warn!("Starting #{self.name.split("::").last} at port #{port}")

        # If we can't connect to the port, keep trying until we can. Print
        # a warning about this once. Try every 0.25s.
        printed_warning = false
        loop do
          begin
            # Call the adapter's new_server method, which should attempt
            # to bind to a port.
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

        # Call the adapter's start_server method.
        start_server
      end

      # This can be overridden in adapters, but shouldn't need to be.
      def self.exit_process(status = 0)
        exit(status)
      end

      def self.process_title(whoami, port)
        name = Merb::Config[:name]
        app  = "merb#{" : #{name}" if (name && name != "merb")}"
        max_port  = Merb::Config[:cluster] ? (Merb::Config[:cluster] - 1) : 0
        numbers   = ((whoami != :worker) && (max_port > 0)) ? "#{port}..#{port + max_port}" : port
        file      = Merb::Config[:socket_file]
        
        listening_on = if Merb::Config[:socket]
          "socket#{'s' if max_port > 0 && whoami != :worker} #{numbers} "\
          "#{file ? file : "#{Merb.log_path}/#{name}.#{port}.sock"}"
        else
          "port#{'s' if max_port > 0 && whoami != :worker}"
        end
        "#{app} : #{whoami} (#{listening_on})"
      end
    end
  end
end
