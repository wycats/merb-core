require 'autotest'
# require File.dirname(__FILE__) + '/textmate'

$VERBOSE = false
  
# cloned from Rspec's autotest settings, but modified 
# to cope w/ Merb's specs directory layout

# ==== Merb Source Autotest Rules
# 1. Updating a spec reruns that spec
# 2. Updating a spec_helper reruns all specs at that level and below
# 3. Updating a file under controller (i.e. abstract_controller.rb)
#    reruns all the specs under (public|private)/abstract_controller
# 4. Updating a file under controller/mixins (e.g. render) 
#    reruns all specs under 
#    (public|private)/(abstract_controller|controller)/render_spec.rb
# 5. Updating a file directly under merb-core (e.g. core_ext.rb)
#    reruns all the specs under spec/(public|private)/core_ext
# 6. Updating merb.rb reruns all specs
class RspecCommandError < StandardError; end

class Autotest::MerbsourceRspec < Autotest
  
  Autotest.add_hook :initialize do |at|
    at.clear_mappings
    at.add_exception(/\.git|log|coverage|doc/)

    # See above for human-readable descriptions of these rules
    # 1 above
    at.add_mapping(%r{^spec/.*_spec\.rb$}) { |filename, _| filename}

    # 2 above
    at.add_mapping(%r{^spec/spec_helper\.rb$}) { |_, m| at.files_matching %r{^spec/.*_spec\.rb$} }
    at.add_mapping(%r{^spec/(.*)/spec_helper\.rb$}) { |_, m| at.files_matching %r{^spec/#{m[1]}/.*_spec\.rb$} }

    # 3 above
    at.add_mapping(%r{^lib/merb-core/controller/([^/]*)\.rb$}) { |_, m| at.files_matching %r{^spec/(public|private)/abstract_controller/.*_spec\.rb} }

    # 4 above
    at.add_mapping(%r{^lib/merb-core/controller/mixins/([^/]*)\.rb$}) { |_, m| at.files_matching %r{^spec/(public|private)/(abstract_)?controller/#{m[1]}_spec\.rb} }

    # 5 above
    at.add_mapping(%r{^lib/merb-core/([^/]*)\.rb$}) { |_, m| at.files_matching %r{^spec/(public|private)/#{m[1]}/.*_spec\.rb} }

    # 6 above
    at.add_mapping(%r{^lib/merb\.rb$}) { at.files_matching %r{^spec/[^/]*_spec\.rb$} }

  end

  def initialize(kernel = Kernel, separator = File::SEPARATOR, alt_separator = File::ALT_SEPARATOR) # :nodoc:
    super() # need parens so that Ruby doesn't pass our args
    # to the superclass version which takes none..    
    
    @kernel, @separator, @alt_separator = kernel, separator, alt_separator
    @spec_command = spec_command
  end
  
  attr_accessor :failures

  def failed_results(results)
    results.scan(/^\d+\)\n(?:\e\[\d*m)?(?:.*?Error in )?'([^\n]*)'(?: FAILED)?(?:\e\[\d*m)?\n(.*?)\n\n/m)
  end

  def handle_results(results)
    @failures = failed_results(results)
    @files_to_test = consolidate_failures @failures
    unless $TESTING
      if @files_to_test.empty?
        hook :green
      else
        hook :red
      end
    end
    @tainted = true unless @files_to_test.empty?
  end

  def consolidate_failures(failed)
    filters = Hash.new { |h,k| h[k] = [] }
    failed.each do |spec, failed_trace|
      find_files.keys.select { |f| f =~ /spec\// }.each do |f|
        if failed_trace =~ Regexp.new(f)
          filters[f] << spec
          break
        end
      end
    end
    filters
  end

  def make_test_cmd(files_to_test)
    "#{ruby} -S #{@spec_command} #{test_cmd_options} #{files_to_test.keys.flatten.join(' ')}"
  end

  def test_cmd_options
    # '-O specs/spec.opts' if File.exist?('specs/spec.opts')
  end
  
  # Finds the proper spec command to use.  Precendence
  # is set in the lazily-evaluated method spec_commands.  Alias + Override
  # that in ~/.autotest to provide a different spec command
  # then the default paths provided.
  def spec_command
    if cmd = spec_commands.detect { |c| File.exist? c }
      @alt_separator ? (cmd.gsub @separator, @alt_separator) : cmd
    else
      raise RspecCommandError, 'No spec command could be found!'
    end
  end
  
  # Merb specs must be run 1 at a time, so use our special runner
  def spec_commands
    [File.join('bin', 'merb-specs')]
  end
end
