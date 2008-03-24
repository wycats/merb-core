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
            unless alive?(port)
              remove_pid_file(port)
              puts "Starting merb server on port: #{port}"
              daemonize(port)
            else
              raise "Merb is already running on port: #{port}"
            end
          end   
        elsif Merb::Config[:daemonize]
          unless alive?(@port)  
            remove_pid_file(@port)
            daemonize(@port)
          else
            raise "Merb is already running on port: #{port}"
          end
        else
          trap('TERM') { exit }
          BootLoader.run
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
        f = "#{Merb.log_path}" / "merb.#{port}.pid"
        pid = IO.read(f).chomp.to_i
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
          Dir[Merb.log_path/ "merb.#{port == 'all' ? '*' : port }.pid"].each do |f|
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
          exit
        end
      end

      # ==== Parameters
      # port<~to_s>:: The port of the Merb process to daemonize.
      def daemonize(port)
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
          if Merb::Config[:user]
            if Merb::Config[:group]
              change_privilege(Merb::Config[:user], Merb::Config[:group])
            else
              change_privilege(Merb::Config[:user])
            end    
          end  
          BootLoader.run
          Merb.adapter.start(Merb::Config.to_hash)
        end
      end

      # Removes a PID file from the filesystem.
      #
      # ==== Parameters
      # port<~to_s>::
      #   The port of the Merb process to whom the the PID file belongs to.
      #
      # ==== Alternatives
      # If Merb::Config[:pid_file] has been specified, that will be used
      # instead of the port based PID file.
      def remove_pid_file(port)
        if Merb::Config[:pid_file]
          pidfile = Merb::Config[:pid_file]
        else
          pidfile = Merb.log_path / "merb.#{port}.pid"
        end
        FileUtils.rm(pidfile) if File.exist?(pidfile)
      end

      # Stores a PID file on the filesystem.
      #
      # ==== Parameters
      # port<~to_s>::
      #   The port of the Merb process to whom the the PID file belongs to.
      #
      # ==== Alternatives
      # If Merb::Config[:pid_file] has been specified, that will be used
      # instead of the port based PID file.
      def store_pid(port)
        FileUtils.mkdir_p(Merb.log_path) unless File.directory?(Merb.log_path)
        if Merb::Config[:pid_file]
          pidfile = Merb::Config[:pid_file]
        else
          pidfile = Merb.log_path / "merb.#{port}.pid"
        end
        File.open(pidfile, 'w'){ |f| f.write("#{Process.pid}") }
      end
          
      # Change privileges of the process to the specified user and group.
      #
      # ==== Parameters
      # user<String>:: The user who should own the server process.
      # group<String>:: The group who should own the server process.
      #
      # ==== Alternatives
      # If group is left out, the user will be used as the group.
      def change_privilege(user, group=user)
        
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