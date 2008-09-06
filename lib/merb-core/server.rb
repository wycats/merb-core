require 'etc'
module Merb

  # Server encapsulates the management of Merb daemons.
  class Server
    class << self

      # Start a Merb server, in either foreground, daemonized or cluster mode.
      #
      # ==== Parameters
      # port<~to_i>::
      #   The port to which the first server instance should bind to.
      #   Subsequent server instances bind to the immediately following ports.
      # cluster<~to_i>::
      #   Number of servers to run in a cluster.
      #
      # ==== Alternatives
      # If cluster is left out, then one process will be started. This process
      # will be daemonized if Merb::Config[:daemonize] is true.
      def start(port, cluster=nil)
        @port = port
        @cluster = cluster
        if @cluster
          @port.to_i.upto(@port.to_i + @cluster.to_i-1) do |port|
            pidfile = pid_file(port)
            pid = IO.read(pidfile).chomp.to_i if File.exist?(pidfile)

            unless alive?(port)
              remove_pid_file(port)
              puts "Starting merb server on port #{port}, pid file: #{pidfile} and process id is #{pid}" if Merb::Config[:verbose]
              daemonize(port)
            else
              raise "Merb is already running: port is #{port}, pid file: #{pidfile}, process id is #{pid}"
            end
          end
        elsif Merb::Config[:daemonize]
          pidfile = pid_file(port)
          pid = IO.read(pidfile).chomp.to_i if File.exist?(pidfile)

          unless alive?(@port)
            remove_pid_file(@port)
            puts "Daemonizing..." if Merb::Config[:verbose]
            daemonize(@port)
          else
            raise "Merb is already running: port is #{port}, pid file: #{pidfile}, process id is #{pid}"
          end
        else
          trap('TERM') { exit }
          trap('INT') { puts "\nExiting"; exit }
          puts "Running bootloaders..." if Merb::Config[:verbose]
          BootLoader.run
          puts "Starting Rack adapter..." if Merb::Config[:verbose]
          Merb.logger.info! "Starting Merb server listening at #{Merb::Config[:host]}:#{port}"
          Merb.adapter.start(Merb::Config.to_hash)
        end
      end

      # ==== Parameters
      # port<~to_s>:: The port to check for Merb instances on.
      #
      # ==== Returns
      # Boolean::
      #   True if Merb is running on the specified port.
      def alive?(port)
        puts "About to check if port #{port} is alive..." if Merb::Config[:verbose]
        pidfile = pid_file(port)
        puts "Pidfile is #{pidfile}..." if Merb::Config[:verbose]
        pid = IO.read(pidfile).chomp.to_i
        puts "Process id is #{pid}" if Merb::Config[:verbose]
        Process.kill(0, pid)
        true
      rescue
        false
      end

      # ==== Parameters
      # port<~to_s>:: The port of the Merb process to kill.
      # sig<~to_s>:: The signal to send to the process. Defaults to 9.
      #
      # ==== Alternatives
      # If you pass "all" as the port, the signal will be sent to all Merb
      # processes.
      def kill(port, sig=9)
        Merb::BootLoader::BuildFramework.run
        begin
          pidfiles = port == "all" ?
            pid_files : [ pid_file(port) ]

          pidfiles.each do |f|
            pid = IO.read(f).chomp.to_i
            begin
              Process.kill(sig, pid)
              FileUtils.rm(f) if File.exist?(f)
              puts "killed PID #{pid} with signal #{sig}"
            rescue Errno::EINVAL
              puts "Failed to kill PID #{pid}: '#{sig}' is an invalid or unsupported signal number."
            rescue Errno::EPERM
              puts "Failed to kill PID #{pid}: Insufficient permissions."
            rescue Errno::ESRCH
              puts "Failed to kill PID #{pid}: Process is deceased or zombie."
              FileUtils.rm f
            rescue Exception => e
              puts "Failed to kill PID #{pid}: #{e.message}"
            end
          end
        ensure
          Merb.started = false
          exit
        end
      end

      # ==== Parameters
      # port<~to_s>:: The port of the Merb process to daemonize.
      def daemonize(port)
        puts "About to fork..." if Merb::Config[:verbose]
        fork do
          Process.setsid
          exit if fork
          File.umask 0000
          STDIN.reopen "/dev/null"
          STDOUT.reopen "/dev/null", "a"
          STDERR.reopen STDOUT
          trap("TERM") { exit }
          Dir.chdir Merb::Config[:merb_root]
          at_exit { remove_pid_file(port) }
          Merb::Config[:port] = port
          BootLoader.run
          Merb.adapter.start(Merb::Config.to_hash)
        end
      end

      def change_privilege
        if Merb::Config[:user]
          if Merb::Config[:group]
            puts "About to change privilege to group #{Merb::Config[:group]} and user #{Merb::Config[:user]}" if Merb::Config[:verbose]
            _change_privilege(Merb::Config[:user], Merb::Config[:group])
          else
            puts "About to change privilege to user #{Merb::Config[:user]}" if Merb::Config[:verbose]
            _change_privilege(Merb::Config[:user])
          end
        end
      end

      # Removes a PID file used by the server from the filesystem.
      # This uses :pid_file options from configuration when provided
      # or merb.<port>.pid in log directory by default.
      #
      # ==== Parameters
      # port<~to_s>::
      #   The port of the Merb process to whom the the PID file belongs to.
      #
      # ==== Alternatives
      # If Merb::Config[:pid_file] has been specified, that will be used
      # instead of the port based PID file.
      def remove_pid_file(port)
        pidfile = pid_file(port)
        puts "Removing pid file #{pidfile} (port is #{port})..."
        FileUtils.rm(pidfile) if File.exist?(pidfile)
      end

      # Stores a PID file on the filesystem.
      # This uses :pid_file options from configuration when provided
      # or merb.<port>.pid in log directory by default.
      #
      # ==== Parameters
      # port<~to_s>::
      #   The port of the Merb process to whom the the PID file belongs to.
      #
      # ==== Alternatives
      # If Merb::Config[:pid_file] has been specified, that will be used
      # instead of the port based PID file.
      def store_pid(port)
        pidfile = pid_file(port)
        puts "Storing pid file to #{pidfile}..."
        FileUtils.mkdir_p(File.dirname(pidfile)) unless File.directory?(File.dirname(pidfile))
        puts "Created directory, writing process id..." if Merb::Config[:verbose]
        File.open(pidfile, 'w'){ |f| f.write("#{Process.pid}") }
      end

      # Gets the pid file for the specified port.
      #
      # ==== Parameters
      # port<~to_s>::
      #   The port of the Merb process to whom the the PID file belongs to.
      #
      # ==== Returns
      # String::
      #   Location of pid file for specified port. If clustered and pid_file option
      #   is specified, it adds the port value to the path.
      def pid_file(port)
        if Merb::Config[:pid_file]
          pidfile = Merb::Config[:pid_file]
          if Merb::Config[:cluster]
            ext = File.extname(Merb::Config[:pid_file])
            base = File.basename(Merb::Config[:pid_file], ext)
            dir = File.dirname(Merb::Config[:pid_file])
            File.join(dir, "#{base}.#{port}#{ext}")
          else
            Merb::Config[:pid_file]
          end
        else
          pidfile = Merb.log_path / "merb.#{port}.pid"
          Merb.log_path / "merb.#{port}.pid"
        end
      end

      # Get a list of the pid files.
      #
      # ==== Returns
      # Array::
      #   List of pid file paths. If not clustered, array contains a single path.
      def pid_files
        if Merb::Config[:pid_file]
          if Merb::Config[:cluster]
            ext = File.extname(Merb::Config[:pid_file])
            base = File.basename(Merb::Config[:pid_file], ext)
            dir = File.dirname(Merb::Config[:pid_file])
            Dir[dir / "#{base}.*#{ext}"]
          else
            [ Merb::Config[:pid_file] ]
          end
        else
          Dir[Merb.log_path / "merb.*.pid"]
        end
       end

      # Change privileges of the process to the specified user and group.
      #
      # ==== Parameters
      # user<String>:: The user who should own the server process.
      # group<String>:: The group who should own the server process.
      #
      # ==== Alternatives
      # If group is left out, the user will be used as the group.
      def _change_privilege(user, group=user)

        puts "Changing privileges to #{user}:#{group}"

        uid, gid = Process.euid, Process.egid
        target_uid = Etc.getpwnam(user).uid
        target_gid = Etc.getgrnam(group).gid

        if uid != target_uid || gid != target_gid
          # Change process ownership
          Process.initgroups(user, target_gid)
          Process::GID.change_privilege(target_gid)
          Process::UID.change_privilege(target_uid)
        end
      rescue Errno::EPERM => e
        puts "Couldn't change user and group to #{user}:#{group}: #{e}"
      end
    end
  end
end
