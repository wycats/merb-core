require 'optparse'
module Merb
  class Config
    class << self
      
      def defaults
        @defaults ||= {
          :host                   => "0.0.0.0",
          :port                   => "4000",
          :adapter                => 'mongrel',
          :reloader               => true,
          :cache_templates        => false,
          :merb_root              => Dir.pwd,
          :use_mutex              => true,
          :session_id_cookie_only => true,
          :query_string_whitelist => [],
          :mongrel_x_sendfile     => true
        }
      end
      
      def [](key)
        (@configuration||={})[key]
      end
      
      def []=(key,val)
        @configuration[key] = val
      end
      def delete(key)
        @configuration.delete key
      end
      
      def fetch(key, default)
        @configuration.fetch key, default
      end
      
      def to_yaml
        @configuration.to_yaml  
      end
      
      def setup(global_merb_yml = nil)
        @configuration ||= {}
        if FileTest.exist? "#{defaults[:merb_root]}/framework"
          $LOAD_PATH.unshift( "#{defaults[:merb_root]}/framework" )
        end
        global_merb_yml ||= "#{defaults[:merb_root]}/config/merb.yml"
        apply_configuration_from_file defaults, global_merb_yml
      end

      def apply_configuration_from_file(configuration, file)
        if File.exists?(file)
          configuration.merge(Erubis.load_yaml_file(file))
        else
          configuration
        end
      end
      
      def parse_args(argv = ARGV)
         @configuration ||= {}
         # Our primary configuration hash for the length of this method
         options = {}

         # Environment variables always win
         options[:environment] = ENV['MERB_ENV'] if ENV['MERB_ENV']

         # Build a parser for the command line arguments
         opts = OptionParser.new do |opts|
           opts.version = Merb::VERSION

           opts.banner = "Usage: merb [fdcepghmisluMG] [argument]"
           opts.define_head "Merb Mongrel+ Erb. Lightweight replacement for ActionPack."
           opts.separator '*'*80
           opts.separator 'If no flags are given, Merb starts in the foreground on port 4000.'
           opts.separator '*'*80

           opts.on("-u", "--user USER", "This flag is for having merb run as a user other than the one currently logged in. Note: if you set this you must also provide a --group option for it to take effect.") do |config|
             options[:user] = config
           end

           opts.on("-G", "--group GROUP", "This flag is for having merb run as a group other than the one currently logged in. Note: if you set this you must also provide a --user option for it to take effect.") do |config|
             options[:group] = config
           end

           opts.on("-f", "--config-file FILENAME", "This flag is for adding extra config files for things like the upload progress module.") do |config|
             options[:config] = config
           end

           opts.on("-d", "--daemonize", "This will run a single merb in the background.") do |config|
             options[:daemonize] = true
           end

           opts.on("-c", "--cluster-nodes NUM_MERBS", "Number of merb daemons to run.") do |nodes|
             options[:cluster] = nodes
           end

           opts.on("-I", "--init-file FILE", "Name of the file to load first") do |init_file|
             options[:init_file] = init_file
           end

           opts.on("-p", "--port PORTNUM", "Port to run merb on, defaults to 4000.") do |port|
             options[:port] = port
           end

           opts.on("-h", "--host HOSTNAME", "Host to bind to (default is all IP's).") do |host|
             options[:host] = host
           end

           opts.on("-m", "--merb-root Merb.root", "The path to the Merb.root for the app you want to run (default is current working dir).") do |root|
             options[:merb_root] = File.expand_path(root)
           end

           opts.on("-a", "--adapter mongrel", "The rack adapter to use to run merb[mongrel, emongrel, thin, fastcgi, webrick]") do |adapter|
             options[:adapter] = adapter
           end


           opts.on("-i", "--irb-console", "This flag will start merb in irb console mode. All your models and other classes will be available for you in an irb session.") do |console|
              options[:adapter] = 'irb'
           end

           opts.on("-l", "--log-level LEVEL", "Log levels can be set to any of these options: DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN") do |loglevel|
             options[:log_level] = loglevel
           end

           opts.on("-e", "--environment STRING", "Run merb in the correct mode(development, production, testing)") do |env|
             options[:environment] ||= env
           end

           opts.on("-r", "--script-runner ['RUBY CODE'| FULL_SCRIPT_PATH]", 
             "Command-line option to run scripts and/or code in the merb app.") do |code_or_file|
               ::Merb::BootLoader.initialize_merb
               if File.exists?(code_or_file)
                 eval(File.read(code_or_file))
               else
                 eval(code_or_file)
               end
               exit!
           end

           opts.on("-P","--generate-plugin PATH", "Generate a fresh merb plugin at PATH.") do |path|
             require 'merb/generators/merb_plugin'
             ::Merb::PluginGenerator.run path || Dir.pwd
             exit
           end

           opts.on("-K", "--graceful PORT or all", "Gracefully kill one merb proceses by port number.  Use merb -K all to gracefully kill all merbs.") do |ports|
             @configuration = defaults.merge(options)
             Merb::Server.kill(ports, 1)
           end
           
           opts.on("-k", "--kill PORT or all", "Kill one merb proceses by port number.  Use merb -k all to kill all merbs.") do |ports|
             @configuration = defaults.merge(options)
             Merb::Server.kill(ports, 9)
           end

           opts.on("-M", "--merb-config FILENAME", "This flag is for explicitly declaring the merb app's config file.") do |config|
             options[:merb_config] = config
           end

           opts.on("-X", "--mutex on/off", "This flag is for turning the mutex lock on and off.") do |mutex|
             if mutex == 'off'
               options[:use_mutex] = false
             else
               options[:use_mutex] = true
             end   
           end

           opts.on("-D", "--debugger", "Run merb using rDebug.") do
             begin
              require 'ruby-debug'
              Debugger.start
              Debugger.settings[:autoeval] = true if Debugger.respond_to?(:settings)
              puts "Debugger enabled"
             rescue LoadError
              puts "You need to install ruby-debug to run the server in debugging mode. With gems, use 'gem install ruby-debug'"
              exit
             end
           end

           opts.on("-?", "-H", "--help", "Show this help message") do
             puts opts  
             exit
           end
         end

         # Parse what we have on the command line
         opts.parse!(argv)

         # merb <argument> is same as merb -g <argument>
         if argv.size == 1
           require 'merb/generators/merb_app/merb_app'
           ::Merb::AppGenerator.run File.expand_path(argv.last)
           exit!
         end

         # Load up the configuration from file, but keep the command line
         # options that may have been chosen. Also, pass-through if we have
         # a new merb_config path.
         options = Merb::Config.setup(options[:merb_config]).merge(options)

         # Finally, if all else fails... set the environment to 'development'
         options[:environment] ||= 'development'

         environment_merb_yml = "#{options[:merb_root]}/config/environments/#{options[:environment]}.yml"        

         @configuration = Merb::Config.apply_configuration_from_file options, environment_merb_yml
         
         # case Merb::Config[:environment].to_s
         # when 'production'
         #   Merb::Config[:reloader] = Merb::Config.fetch(:reloader, false)
         #   Merb::Config[:exception_details] = Merb::Config.fetch(:exception_details, false)
         #   Merb::Config[:cache_templates] = true
         # else
         #   Merb::Config[:reloader] = Merb::Config.fetch(:reloader, true)
         #   Merb::Config[:exception_details] = Merb::Config.fetch(:exception_details, true)
         # end
         # 
         # Merb::Config[:reloader_time] ||= 0.5 if Merb::Config[:reloader] == true
         # 
         # 
         # if Merb::Config[:reloader]
         #   Thread.abort_on_exception = true
         #   Thread.new do
         #     loop do
         #       sleep( Merb::Config[:reloader_time] )
         #       ::Merb::BootLoader.reload if ::Merb::BootLoader.app_loaded?
         #     end
         #     Thread.exit
         #   end
         # end
         @configuration
       end
       
    end # class << self
  end # Config
  
end