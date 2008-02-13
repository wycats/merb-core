require 'etc'
module Merb
  
  # Server encapsulates the management of merb daemons
  class Server
    class << self

      # Start a merb server, in either foreground, daemonized or cluster mode
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

      # Check to see if there is already a merb running on this port
      def alive?(port)
        f = "#{Merb.dir_for(:log)}" / "merb.#{port}.pid"
        pid = IO.read(f).chomp.to_i
        Process.kill(0, pid)
        true
      rescue
        false
      end

      # Killa  merb process with a certain signal.
      def kill(port, sig=9)
        Merb::BootLoader::BuildFramework.run
        begin
          Dir[Merb.dir_for(:log) / "merb.#{port == 'all' ? '*' : port }.pid"].each do |f|
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

      # Daemonize a merb server running on a specified port
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

      # Remove PID file from the filesystem
      def remove_pid_file(port)
        if Merb::Config[:pid_file]
          pidfile = Merb::Config[:pid_file]
        else
          pidfile = Merb.dir_for(:log) / "merb.#{port}.pid"
        end
        FileUtils.rm(pidfile) if File.exist?(pidfile)
      end

      # Store PID file on the filesystem
      def store_pid(port)
        FileUtils.mkdir_p(Merb.dir_for(:log)) unless File.directory?(Merb.dir_for(:log))
        if Merb::Config[:pid_file]
          pidfile = Merb::Config[:pid_file]
        else
          pidfile = Merb.dir_for(:log) / "merb.#{port}.pid"
        end
        File.open(pidfile, 'w'){ |f| f.write("#{Process.pid}") }
      end
          
      # Change privileges of the process
      # to the specified user and group.
      # if you only specify user, group 
      # will be the same as user.
      def change_privilege(user, group=user)
        Merb.logger.info "Changing privileges to #{user}:#{group}"
        
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
        Merb.logger.error "Couldn't change user and group to #{user}:#{group}: #{e}"
      end
    end
  end
end    