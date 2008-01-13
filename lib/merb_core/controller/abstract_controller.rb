# Note that the over-use of "_" in Controller methods is to avoid collisions with
# helpers, which will be pulled directly into controllers from now on
#
# ==== Filters
# #before is a class method that allows you to specify before filters in
# your controllers. Filters can either be a symbol or string that
# corresponds to a method name to call, or a proc object. if it is a method
# name that method will be called and if it is a proc it will be called
# with an argument of self where self is the current controller object.
# When you use a proc as a filter it needs to take one parameter.
# 
# #after is identical, but the filters are run after the action is invoked.
#
# ==== Examples
#   before :some_filter
#   before :authenticate, :exclude => [:login, :signup]
#   before Proc.new {|c| c.some_method }, :only => :foo
#
# You can use either :only => :actionname or :exclude => [:this, :that]
# but not both at once. :only will only run before the listed actions
# and :exclude will run for every action that is not listed.
#
# Merb's before filter chain is very flexible. To halt the filter chain you
# use throw :halt. If throw is called with only one argument of :halt the
# return of the method filters_halted will be what is rendered to the view.
# You can overide filters_halted in your own controllers to control what it
# outputs. But the throw construct is much more powerful then just that.
# throw :halt can also take a second argument. Here is what that second arg
# can be and the behavior each type can have:
#
# * +String+:
#   when the second arg is a string then that string will be what
#   is rendered to the browser. Since merb's render method returns
#   a string you can render a template or just use a plain string:
#
#     throw :halt, "You don't have permissions to do that!"
#     throw :halt, render(:action => :access_denied)
#
# * +Symbol+:
#   If the second arg is a symbol then the method named after that
#   symbol will be called
#
#   throw :halt, :must_click_disclaimer
#
# * +Proc+:
#
#   If the second arg is a Proc, it will be called and its return
#   value will be what is rendered to the browser:
#
#     throw :halt, proc {|c| c.access_denied }
#     throw :halt, proc {|c| Tidy.new(c.index) }
#
# ==== Filter Options (.before, .after, .add_filter)
# :only<Symbol, Array[Symbol]>::
#   A list of actions that this filter should apply to
#
# :exclude<Symbol, Array[Symbol]::
#   A list of actions that this filter should *not* apply to
# 
# ==== Types (shortcuts for use in this file)
# Filter:: <Array[Symbol, (Symbol, String, Proc)]>
class Merb::AbstractController
  include Merb::RenderMixin
  include Merb::GeneralControllerMixin
  
  class_inheritable_accessor :_before_filters, :_after_filters, :_template_root
  self._before_filters, self._after_filters = [], []
  self._template_root = Merb.load_paths[:view]
  
  # This is called after the controller is instantiated to figure out
  # where to look for templates under the _template_root. Override this
  # to define a new structure for your app.
  #
  # ==== Examples
  # {{[
  #   def _template_location
  #     "#{params[:controller]}.#{prams[:action]}.#{content_type}"
  # ]}}
  #
  # This would look for templates at controller.action.mime.type instead
  # of controller/action.mime.type
  def _template_location
    "#{params[:controller]}/#{params[:action]}.#{content_type}"
  end
  
  cattr_accessor :_abstract_subclasses, :_template_path_cache
  #---
  # We're using abstract_subclasses so that Merb::Controller can have its
  # own subclasses. We're using a Set so we don't have to worry about
  # uniqueness.
  self._abstract_subclasses = Set.new
  def self.subclasses_list() _abstract_subclasses end
  
  class << self
    # ==== Parameters
    # klass<Merb::AbstractController>::
    #   The controller that is being inherited from Merb::AbstractController
    def inherited(klass)
      _abstract_subclasses << klass.to_s
      super
    end
  end
  
  attr_accessor :_benchmarks, :_thrown_content
  
  # ==== Parameters
  # *args<Object>:: The args are ignored
  def initialize(*args)
    @_benchmarks = {}
    @thrown_content = AbstractController._default_thrown_content    
  end
  
  # ==== Parameters
  # action<~to_s>:: The action to dispatch to. This will be #send'ed in _call_action
  def _dispatch(action=:to_s)
    caught = catch(:halt) do
      start = Time.now
      result = _call_filters(_before_filters)
      @_benchmarks[:before_filters_time] = Time.now - start if _before_filters
      result
    end
  
    @_body = case caught
    when :filter_chain_completed  then _call_action(action)
    when String                   then caught
    when nil                      then _filters_halted
    when Symbol                   then send(caught)
    when Proc                     then caught.call(self)
    else
      raise MerbControllerError, "The before filter chain is broken dude. wtf?"
    end
    start = Time.now
    _call_filters(_after_filters) 
    @_benchmarks[:after_filters_time] = Time.now - start if after_filters
  end
  
  # This method exists to provide an overridable hook for ActionArgs
  #
  # ==== Parameters
  # action<~to_s>:: the action method to dispatch to
  def _call_action(action)
    send(action)
  end
  
  # ==== Parameters
  # filter_set<Array[Filter]>::
  #   A set of filters in the form [[:filter, rule], [:filter, rule]]
  #
  # ==== Filters
  # Filter rules can be Symbols, Strings, or Procs.
  #
  # When they are Symbols or Strings:
  # * call the method represented by the +Symbol+ or +String+
  # When they are +Procs:
  # * execute the +Proc+, in the context of the controller (self will
  #   be the controller)
  def _call_filters(filter_set)
    action = params[:action].intern
    
    (filter_set || []).each do |filter, rule|
      # Both:
      # * no :only or the current action is in the :only list
      # * no :exclude or the current action is not in the :exclude list
      if (!rule.key?(:only) || rule[:only].include?(action)) &&
      (!rule.key?(:exclude) || !rule[:exclude].include?(action))
        case filter
        when Symbol, String then send(filter)
        when Proc           then self.instance_eval(&filter)
    end
    return :filter_chain_completed
  end

  # ==== Parameters
  # filter<Symbol, Proc>:: The filter to add
  # opts<Hash>:: A Hash of options (see below)
  #
  # ==== Options
  # See class documentation under <tt>Filter Options</tt>
  #
  # ==== Note
  # If the filter already exists, its options will be replaced
  # with opts
  def self.after(filter, opts = {})
    add_filter(self._after_filters, filter, opts)
  end

  # ==== Parameters
  # filter<Symbol, Proc>:: The filter to add
  # opts<Hash>:: A Hash of options (see below)
  #
  # ==== Options
  # See class documentation under <tt>Filter Options</tt>
  #
  # ==== Note
  # If the filter already exists, its options will be replaced with opts  
  def self.before(filter, opts = {})
    add_filter(self._before_filters, filter, opts)
  end
     
  # Skip an after filter that has been previously defined (perhaps in a superclass)
  #
  # ==== Parameters
  # filter<Symbol>:: A filter name to skip
  def self.skip_after(filter)
    skip_filter(self._after_filters, filter)
  end
  
  # Skip a before filter that has been previously defined (perhaps in a superclass)
  #
  # ==== Parameters
  # filter<Symbol>:: A filter name to skip  
  def self.skip_before(filter)
    skip_filter(self._before_filters, filter)
  end  
  
  #---
  # Defaults that can be overridden by plugins or other mixins
  
  def _filters_halted()   "<html><body><h1>Filter Chain Halted!</h1></body></html>"  end
  def _setup_session()                                                               end    
  def _finalize_session()                                                            end
  
  # Handles the template cache (which is used by BootLoader to cache the list of all templates)
  #
  # ==== Parameters
  # template<String>:: The full path to a template to add to the list of available templates
  def self.add_path_to_template_cache(template)
    return false if template.blank? || template.split("/").last.split(".").size != 3
    key = template.match(/(.*)\.(.*)$/)[1]
    self._template_path_cache[key] = template
  end
  
  # Resets the template_path_cache to an empty hash
  def self.reset_template_path_cache!
    self._template_path_cache = {}
  end  
  
  private
  # ==== Parameters
  # filters<Array[Filter]>:: 
  #   The filter list that this should be added to
  # filter<Filter>:: A filter that should be added
  # opts<Hash>:: Options (see below)
  # 
  # ==== Options
  # See class documentation under <tt>Filter Options</tt>
  def self.add_filter(filters, filter, opts={})
    raise(ArgumentError,
      "You can specify either :only or :exclude but 
       not both at the same time for the same filter.") if opts.key?(:only) && opts.key?(:exclude)

    opts = normalize_filters!(opts)

    case filter
    when Symbol, Proc, String
      if existing_filter = filters.find {|f| f.first.to_s[filter.to_s]}
        existing_filter.last.replace(opts)
      else
        filters << [filter, opts]
      end
    else
      raise(ArgumentError, 
        'Filters need to be either a Symbol, String or a Proc'
      )        
    end
  end  

  # Skip a filter that was previously added to the filter chain. Useful in
  # inheritence hierarchies
  #
  # ==== Parameters
  # filters<Array[Filter]>:: 
  #   The filter list that this should be removed from
  # filter<Filter>:: A filter that should be removed
  def self.skip_filter(filters, filter)
    raise(ArgumentError, 'You can only skip filters that have a String or Symbol name.') unless
      [Symbol, String].include? filter.class

    Merb.logger.warn("Filter #{filter} was not found in your filter chain.") unless
      filters.reject! {|f| f.first.to_s[filter.to_s] }
  end

  # Ensures that the passed in hash values are always arrays.
  #
  #   normalize_filters!(:only => :new) #=> {:only => [:new]}  
  #
  # ==== Parameters
  # opts<Hash>:: Options (see below)
  #
  # ==== Options
  # :only<Symbol, Array[Symbol]>:: A list of actions
  # :exclude<Symbol, Array[Symbol]>:: A list of actions
  def self.normalize_filters!(opts={})
    opts[:only] = [opts[:only]] if opts[:only].is_a?(Symbol)       
    opts[:exclude] = [opts[:exclude]] if opts[:exclude].is_a?(Symbol)
    return opts
  end
end