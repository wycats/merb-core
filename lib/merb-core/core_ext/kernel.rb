require 'rubygems/dependency'

module Gem
  class Dependency
    attr_accessor :require_block
  end
end

module Kernel
  
  # Keep track of all required dependencies. 
  #
  # @param name<String> The name of the gem to load.
  # @param *ver<Gem::Requirement, Gem::Version, Array, #to_str>
  #   Version requirements to be passed to Gem::Dependency.new.
  #
  # @return <Gem::Dependency> Dependency information
  #
  # @api private
  def track_dependency(name, *ver, &blk)
    dep = Gem::Dependency.new(name, ver)
    dep.require_block = blk
    
    existing = Merb::BootLoader::Dependencies.dependencies.find { |d| d.name == dep.name }
    if existing
      index = Merb::BootLoader::Dependencies.dependencies.index(existing)
      Merb::BootLoader::Dependencies.dependencies.delete(existing)
      Merb::BootLoader::Dependencies.dependencies.insert(index, dep)
    else
      Merb::BootLoader::Dependencies.dependencies << dep
    end
    return dep
  end
  
  # Loads the given string as a gem. Execution is deferred until
  # after the logger has been instantiated and the framework directory
  # structure is defined.
  #
  # If that has already happened, the gem will be activated
  # immediately, but it will still be registered.
  # 
  # ==== Parameters
  # name<String> The name of the gem to load.
  # *ver<Gem::Requirement, Gem::Version, Array, #to_str>
  #   Version requirements to be passed to Gem::Dependency.new.
  #   If the last argument is a Hash, extract the :immediate option,
  #   forcing a dependency to load immediately.
  #
  # ==== Returns
  # Gem::Dependency:: The dependency information.
  #
  # @api public
  def dependency(name, *ver, &blk)
    immediate = ver.last.is_a?(Hash) && ver.pop[:immediate]
    if immediate || Merb::BootLoader.finished?(Merb::BootLoader::Dependencies)
      load_dependency(name, *ver, &blk)
    else
      track_dependency(name, *ver, &blk)
    end
  end

  # Loads the given string as a gem.
  #
  # This new version tries to load the file via ROOT/gems first before moving
  # off to the system gems (so if you have a lower version of a gem in
  # ROOT/gems, it'll still get loaded).
  #
  # @param name<String,Gem::Dependency> 
  #   The name or dependency object of the gem to load.
  # @param *ver<Gem::Requirement, Gem::Version, Array, #to_str>
  #   Version requirements to be passed to Gem.activate.
  #
  # @note
  #   If the gem cannot be found, the method will attempt to require the string
  #   as a library.
  #
  # @return <Gem::Dependency> The dependency information.
  #
  # @api private
  def load_dependency(name, *ver, &blk)
    dep = name.is_a?(Gem::Dependency) ? name : track_dependency(name, *ver)
    gem(dep)
  rescue Gem::LoadError => e
    Merb.fatal! "The gem #{name}, #{ver.inspect} was not found", e
  ensure
    if block = blk || dep.require_block
      block.call
    else
      begin
        require dep.name
      rescue LoadError => e
        Merb.fatal! "The file #{dep.name} was not found", e
      end
    end
    Merb.logger.info!("loading gem '#{dep.name}' ...")
    return dep # ensure needs explicit return
  end

  # Loads both gem and library dependencies that are passed in as arguments.
  # Execution is deferred to the Merb::BootLoader::Dependencies.run during bootup.
  #
  # ==== Parameters
  # *args<String, Hash, Array> The dependencies to load.
  #
  # ==== Returns
  # Array[(Gem::Dependency, Array[Gem::Dependency])]:: Gem::Dependencies for the
  #   dependencies specified in args.
  #
  # @api public
  def dependencies(*args)
    args.map do |arg|
      case arg
      when String then dependency(arg)
      when Hash   then arg.map { |r,v| dependency(r, v) }
      when Array  then arg.map { |r|   dependency(r)    }
      end
    end
  end

  # Loads both gem and library dependencies that are passed in as arguments.
  #
  # @param *args<String, Hash, Array> The dependencies to load.
  #
  # @note
  #   Each argument can be:
  #   String:: Single dependency.
  #   Hash::
  #     Multiple dependencies where the keys are names and the values versions.
  #   Array:: Multiple string dependencies.
  #
  # @example dependencies "RedCloth"                 # Loads the the RedCloth gem
  # @example dependencies "RedCloth", "merb_helpers" # Loads RedCloth and merb_helpers
  # @example dependencies "RedCloth" => "3.0"        # Loads RedCloth 3.0
  #
  # @api private
  def load_dependencies(*args)
    args.map do |arg|
      case arg
      when String then load_dependency(arg)
      when Hash   then arg.map { |r,v| load_dependency(r, v) }
      when Array  then arg.map { |r|   load_dependency(r)    }
      end
    end
  end

  # Does a basic require, and prints a message if an error occurs.
  #
  # @param library<to_s> The library to attempt to include.
  # @param message<String> The error to add to the log upon failure. Defaults to nil.
  #
  # @api private
  # @deprecated
  def rescue_require(library, message = nil)
    Merb.logger.warn("Deprecation warning: rescue_require is deprecated")
    sleep 2.0
    require library
  rescue LoadError, RuntimeError
    Merb.logger.error!(message) if message
  end

  # Used in Merb.root/config/init.rb to tell Merb which ORM (Object Relational
  # Mapper) you wish to use. Currently Merb has plugins to support
  # ActiveRecord, DataMapper, and Sequel.
  #
  # ==== Parameters
  # orm<Symbol>:: The ORM to use.
  #
  # ==== Returns
  # nil
  #
  # ==== Example
  #   use_orm :datamapper
  #
  #   # This will use the DataMapper generator for your ORM
  #   $ merb-gen model ActivityEvent
  #
  # ==== Notes
  #   If for some reason this is called more than once, latter
  #   call takes over other.
  #
  # @api public
  def use_orm(orm)
    begin
      Merb.orm = orm
      orm_plugin = "merb_#{orm}"
      Kernel.dependency(orm_plugin)
    rescue LoadError => e
      Merb.logger.warn!("The #{orm_plugin} gem was not found.  You may need to install it.")
      raise e
    end
    nil
  end

  # Used in Merb.root/config/init.rb to tell Merb which testing framework to
  # use. Currently Merb has plugins to support RSpec and Test::Unit.
  #
  # ==== Parameters
  # test_framework<Symbol>::
  #   The test framework to use. Currently only supports :rspec and :test_unit.
  #
  # ==== Returns
  # nil
  #
  # ==== Example
  #   use_test :rspec
  #
  #   # This will now use the RSpec generator for tests
  #   $ merb-gen model ActivityEvent
  #
  # @api public
  def use_test(test_framework, *test_dependencies)
    Merb.test_framework = test_framework
    
    Kernel.dependencies test_dependencies if Merb.env == "test" || Merb.env.nil?
    nil
  end
  
  # Used in Merb.root/config/init.rb to tell Merb which template engine to
  # prefer.
  #
  # ==== Parameters
  # template_engine<Symbol>
  #   The template engine to use.
  #
  # ==== Returns
  # nil
  #
  # ==== Example
  #   use_template_engine :haml
  #
  #   # This will now use haml templates in generators where available.
  #   $ merb-gen resource_controller Project 
  #
  # @api public
  def use_template_engine(template_engine)
    Merb.template_engine = template_engine

    if template_engine != :erb
      if template_engine.in?(:haml, :builder)
        template_engine_plugin = "merb-#{template_engine}"
      else
        template_engine_plugin = "merb_#{template_engine}"
      end
      Kernel.dependency(template_engine_plugin)
    end
    
    nil
  rescue LoadError => e
    Merb.logger.warn!("The #{template_engine_plugin} gem was not found.  You may need to install it.")
    raise e
  end


  # @param i<Fixnum> The caller number. Defaults to 1.
  #
  # @return <Array[Array]> The file, line and method of the caller.
  #
  # @example
  #   __caller_info__(1)
  #     # => ['/usr/lib/ruby/1.8/irb/workspace.rb', '52', 'irb_binding']
  #
  # @api private
  def __caller_info__(i = 1)
    file, line, meth = caller[i].scan(/(.*?):(\d+):in `(.*?)'/).first
  end

  # @param file<String> The file to read.
  # @param line<Fixnum> The line number to look for.
  # @param size<Fixnum>
  #   Number of lines to include above and below the the line to look for.
  #   Defaults to 4.
  #
  # @return <Array[Array]>
  #   Triplets containing the line number, the line and whether this was the
  #   searched line.
  #
  # @example
  #   __caller_lines__('/usr/lib/ruby/1.8/debug.rb', 122, 2) # =>
  #     [
  #       [ 120, "  def check_suspend",                               false ],
  #       [ 121, "    return if Thread.critical",                     false ],
  #       [ 122, "    while (Thread.critical = true; @suspend_next)", true  ],
  #       [ 123, "      DEBUGGER__.waiting.push Thread.current",      false ],
  #       [ 124, "      @suspend_next = false",                       false ]
  #     ]
  #
  # @api private
  def __caller_lines__(file, line, size = 4)
    line = line.to_i
    if file =~ /\(erubis\)/
      yield :error, "Template Error! Problem while rendering", false
    elsif !File.file?(file) || !File.readable?(file)
      yield :error, "File `#{file}' not available", false
    else
      lines = File.read(file).split("\n")
      first_line = (f = line - size - 1) < 0 ? 0 : f
      
      old_lines = lines
      lines = lines[first_line, size * 2 + 1]

      lines && lines.each_with_index do |str, index|
        yield index + line - size, str.chomp
      end
    end
  end

  # Takes a block, profiles the results of running the block
  # specified number of times and generates HTML report.
  #
  # @param name<#to_s>
  #   The file name. The result will be written out to
  #   Merb.root/"log/#{name}.html".
  # @param min<Fixnum>
  #   Minimum percentage of the total time a method must take for it to be
  #   included in the result. Defaults to 1.
  #
  # @return <String>
  #   The result of the profiling.
  #
  # @note
  #   Requires ruby-prof (<tt>sudo gem install ruby-prof</tt>)
  #
  # @example
  #   __profile__("MyProfile", 5, 30) do
  #     rand(10)**rand(10)
  #     puts "Profile run"
  #   end
  #
  #   Assuming that the total time taken for #puts calls was less than 5% of the
  #   total time to run, #puts won't appear in the profile report.
  #   The code block will be run 30 times in the example above.
  #
  # @api private
  def __profile__(name, min=1, iter=100)
    require 'ruby-prof' unless defined?(RubyProf)
    return_result = ''
    result = RubyProf.profile do
      iter.times{return_result = yield}
    end
    printer = RubyProf::GraphHtmlPrinter.new(result)
    path = File.join(Merb.root, 'log', "#{name}.html")
    File.open(path, 'w') do |file|
      printer.print(file, {:min_percent => min,
                      :print_file => true})
    end
    return_result
  end

  # Extracts an options hash if it is the last item in the args array. Used
  # internally in methods that take *args.
  #
  # @param args<Array> The arguments to extract the hash from.
  #
  # @example
  #   def render(*args,&blk)
  #     opts = extract_options_from_args!(args) || {}
  #     # [...]
  #   end
  #
  # @api public
  def extract_options_from_args!(args)
    args.pop if Hash === args.last
  end

  # Checks that the given objects quack like the given conditions.
  #
  # @param opts<Hash>
  #   Conditions to enforce. Each key will receive a quacks_like? call with the
  #   value (see Object#quacks_like? for details).
  #
  # @raise <ArgumentError>
  #   An object failed to quack like a condition.
  #
  # @api public
  def enforce!(opts = {})
    opts.each do |k,v|
      raise ArgumentError, "#{k.inspect} doesn't quack like #{v.inspect}" unless k.quacks_like?(v)
    end
  end

  unless Kernel.respond_to?(:debugger)

    # Define debugger method so that code even works if debugger was not
    # requested. Drops a note to the logs that Debugger was not available.
    def debugger
      Merb.logger.info! "\n***** Debugger requested, but was not " +
        "available: Start server with --debugger " +
        "to enable *****\n"
    end
  end
  
end
