require 'etc'

module Merb
  class Daemons
    def initialize(port, cluster=nil)
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

    def alive?(port)
      f = "#{Merb.dir_for(:log)}" / "merb.#{port}.pid"
      pid = IO.read(f).chomp.to_i
      Process.kill(0, pid)
      true
    rescue
      false
    end
    
    def kill(port, sig=9)
      begin
        Dir[Merb::Config[:merb_root] + "/log/merb.#{ports == 'all' ? '*' : port }.pid"].each do |f|
          pid = IO.read(f).chomp.to_i
          Process.kill(sig, pid)
          puts "killed PID #{pid} with signal #{sig}"
        end
      rescue
        puts "Failed to kill! #{k}"
      ensure  
        exit
      end
    end
    
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
        store_pid(port)
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
    
    def remove_pid_file(port)
      pidfile = "#{Merb.dir_for(:log)}" / "merb.#{port}.pid"
      FileUtils.rm(pidfile) if File.exist?(pidfile)
    end
    
    def store_pid(port)
      File.open(("#{Merb.dir_for(:log)}" / "merb.#{port}.pid"), 'w'){|f| f.write("#{Process.pid}")}
    end
        
    # Change privileges of the process
    # to the specified user and group.
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