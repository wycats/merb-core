# ==== Why do we use Underscores?
# In Merb, views are actually methods on controllers. This provides
# not-insignificant speed benefits, as well as preventing us from
# needing to copy over instance variables, which we think is proof
# that everything belongs in one class to begin with.
#
# Unfortunately, this means that view helpers need to be included
# into the <strong>Controller</strong> class. To avoid causing confusion
# when your helpers potentially conflict with our instance methods,
# we use an _ to disambiguate. As long as you don't begin your helper
# methods with _, you only need to worry about conflicts with Merb
# methods that are part of the public API.
#
#
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
# ===== Examples
#   before :some_filter
#   before :authenticate, :exclude => [:login, :signup]
#   before :has_role, :with => ["Admin"], :exclude => [:index, :show]
#   before Proc.new { some_method }, :only => :foo
#   before :authorize, :unless => :logged_in?  
#
# You can use either <code>:only => :actionname</code> or 
# <code>:exclude => [:this, :that]</code> but not both at once. 
# <code>:only</code> will only run before the listed actions and 
# <code>:exclude</code> will run for every action that is not listed.
#
# Merb's before filter chain is very flexible. To halt the filter chain you
# use <code>throw :halt</code>. If <code>throw</code> is called with only one 
# argument of <code>:halt</code> the return value of the method 
# <code>filters_halted</code> will be what is rendered to the view. You can 
# override <code>filters_halted</code> in your own controllers to control what 
# it outputs. But the <code>throw</code> construct is much more powerful than 
# just that.
#
# <code>throw :halt</code> can also take a second argument. Here is what that 
# second argument can be and the behavior each type can have:
#
# * +String+:
#   when the second argument is a string then that string will be what
#   is rendered to the browser. Since merb's <code>#render</code> method returns
#   a string you can render a template or just use a plain string:
#
#     throw :halt, "You don't have permissions to do that!"
#     throw :halt, render(:action => :access_denied)
#
# * +Symbol+:
#   If the second arg is a symbol, then the method named after that
#   symbol will be called
#
#     throw :halt, :must_click_disclaimer
#
# * +Proc+:
#   If the second arg is a Proc, it will be called and its return
#   value will be what is rendered to the browser:
#
#     throw :halt, proc { access_denied }
#     throw :halt, proc { Tidy.new(c.index) }
#
# ===== Filter Options (.before, .after, .add_filter, .if, .unless)
# :only<Symbol, Array[Symbol]>::
#   A list of actions that this filter should apply to
#
# :exclude<Symbol, Array[Symbol]::
#   A list of actions that this filter should *not* apply to
# 
# :if<Symbol, Proc>::
#   Only apply the filter if the method named after the symbol or calling the proc evaluates to true
# 
# :unless<Symbol, Proc>::
#   Only apply the filter if the method named after the symbol or calling the proc evaluates to false
#
# :with<Array[Object]>::
#   Arguments to be passed to the filter. Since we are talking method/proc calls,
#   filter method or Proc should to have the same arity
#   as number of elements in Array you pass to this option.
#
# ===== Types (shortcuts for use in this file)
# Filter:: <Array[Symbol, (Symbol, String, Proc)]>
#
# ==== params[:action] and params[:controller] deprecated
# <code>params[:action]</code> and <code>params[:controller]</code> have been deprecated as of
# the 0.9.0 release. They are no longer set during dispatch, and
# have been replaced by <code>action_name</code> and <code>controller_name</code> respectively.
class Merb::AbstractController
  include Merb::RenderMixin
  include Merb::InlineTemplates
  
  class_inheritable_accessor :_layout, :_template_root, :template_roots
  class_inheritable_accessor :_before_filters, :_after_filters
  class_inheritable_accessor :_before_dispatch_callbacks, :_after_dispatch_callbacks

  cattr_accessor :_abstract_subclasses

  #---
  # @semipublic
  attr_accessor :body
  attr_accessor :action_name
  attr_accessor :_benchmarks, :_thrown_content  

  # Stub so content-type support in RenderMixin doesn't throw errors
  attr_accessor :content_type

  FILTER_OPTIONS = [:only, :exclude, :if, :unless, :with]

  self._before_filters, self._after_filters = [], []
  self._before_dispatch_callbacks, self._after_dispatch_callbacks = [], []

  #---
  # We're using abstract_subclasses so that Merb::Controller can have its
  # own subclasses. We're using a Set so we don't have to worry about
  # uniqueness.
  self._abstract_subclasses = Set.new

  # ==== Returns
  # String:: The controller name in path form, e.g. "admin/items".
  #---
  # @public
  def self.controller_name() @controller_name ||= self.name.to_const_path end

  # ==== Returns
  # String:: The controller name in path form, e.g. "admin/items".
  def controller_name()      self.class.controller_name                   end
  
  # This is called after the controller is instantiated to figure out where to
  # look for templates under the _template_root. Override this to define a new
  # structure for your app.
  #
  # ==== Parameters
  # context<~to_s>:: The controller context (the action or template name).
  # type<~to_s>:: The content type. Defaults to nil.
  # controller<~to_s>::
  #   The name of the controller. Defaults to controller_name.
  #
  #
  # ==== Returns
  # String:: 
  #   Indicating where to look for the template for the current controller,
  #   context, and content-type.
  #
  # ==== Notes
  # The type is irrelevant for controller-types that don't support
  # content-type negotiation, so we default to not include it in the
  # superclass.
  #
  # ==== Examples
  #   def _template_location
  #     "#{params[:controller]}.#{params[:action]}.#{content_type}"
  #   end
  #
  # This would look for templates at controller.action.mime.type instead
  # of controller/action.mime.type
  #---
  # @public
  def _template_location(context, type, controller)
    controller ? "#{controller}/#{context}" : context
  end

  # The location to look for a template - stub method for particular behaviour.
  #
  # ==== Parameters
  # template<String>:: The absolute path to a template - without template extension.
  # type<~to_s>::
  #    The mime-type of the template that will be rendered. Defaults to nil.
  #
  # @public
  def _absolute_template_location(template, type)
    template
  end

  def self._template_root=(root)
    @_template_root = root
    _reset_template_roots
  end

  def self._reset_template_roots
    self.template_roots = [[self._template_root, :_template_location]]
  end

  # ==== Returns
  # roots<Array[Array]>::
  #   Template roots as pairs of template root path and template location
  #   method.
  def self._template_roots
    self.template_roots || _reset_template_roots
  end

  # ==== Parameters
  # roots<Array[Array]>::
  #   Template roots as pairs of template root path and template location
  #   method.
  def self._template_roots=(roots)
    self.template_roots = roots
  end
  
  # ==== Returns
  # Set:: The subclasses.
  def self.subclasses_list() _abstract_subclasses end
  
  class << self
    # ==== Parameters
    # klass<Merb::AbstractController>::
    #   The controller that is being inherited from Merb::AbstractController
    def inherited(klass)
      _abstract_subclasses << klass.to_s
      helper_module_name = klass.to_s =~ /^(#|Merb::)/ ? "#{klass}Helper" : "Merb::#{klass}Helper"
      Object.make_module helper_module_name
      klass.class_eval <<-HERE
        include Object.full_const_get("#{helper_module_name}") rescue nil
      HERE
      super
    end    
  end
  
  # ==== Parameters
  # *args:: The args are ignored.
  def initialize(*args)
    @_benchmarks = {}
    @_caught_content = {}
    @_template_stack = []
  end
  
  # This will dispatch the request, calling internal before/after dispatch_callbacks
  # 
  # ==== Parameters
  # action<~to_s>::
  #   The action to dispatch to. This will be #send'ed in _call_action.
  #   Defaults to :to_s.
  #
  # ==== Raises
  # MerbControllerError:: Invalid body content caught.
  def _dispatch(action)
    self._before_dispatch_callbacks.each { |cb| cb.call(self) }
    self.action_name = action
    
    caught = catch(:halt) do
      start = Time.now
      result = _call_filters(_before_filters)
      @_benchmarks[:before_filters_time] = Time.now - start if _before_filters
      result
    end
  
    @body = case caught
    when :filter_chain_completed  then _call_action(action_name)
    when String                   then caught
    when nil                      then _filters_halted
    when Symbol                   then __send__(caught)
    when Proc                     then self.instance_eval(&caught)
    else
      raise ArgumentError, "Threw :halt, #{caught}. Expected String, nil, Symbol, Proc."
    end
    start = Time.now
    _call_filters(_after_filters)
    @_benchmarks[:after_filters_time] = Time.now - start if _after_filters
    
    self._after_dispatch_callbacks.each { |cb| cb.call(self) }
    
    @body
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
  # ==== Returns
  # Symbol:: :filter_chain_completed.
  #
  # ==== Notes
  # Filter rules can be Symbols, Strings, or Procs.
  #
  # Symbols or Strings::
  #   Call the method represented by the +Symbol+ or +String+.
  # Procs::
  #   Execute the +Proc+, in the context of the controller (self will be the
  #   controller)
  def _call_filters(filter_set)
    (filter_set || []).each do |filter, rule|
      if _call_filter_for_action?(rule, action_name) && _filter_condition_met?(rule)
        case filter
        when Symbol, String
          if rule.key?(:with)
            args = rule[:with]
            send(filter, *args)
          else
            send(filter)
          end
        when Proc then self.instance_eval(&filter)
        end
      end
    end
    return :filter_chain_completed
  end

  # ==== Parameters
  # rule<Hash>:: Rules for the filter (see below).
  # action_name<~to_s>:: The name of the action to be called.
  #
  # ==== Options (rule)
  # :only<Array>::
  #   Optional list of actions to fire. If given, action_name must be a part of
  #   it for this function to return true.
  # :exclude<Array>::
  #   Optional list of actions not to fire. If given, action_name must not be a
  #   part of it for this function to return true.
  #
  # ==== Returns
  # Boolean:: True if the action should be called.
  def _call_filter_for_action?(rule, action_name)
    # Both:
    # * no :only or the current action is in the :only list
    # * no :exclude or the current action is not in the :exclude list
    (!rule.key?(:only) || rule[:only].include?(action_name)) &&
    (!rule.key?(:exclude) || !rule[:exclude].include?(action_name))
  end

  # ==== Parameters
  # rule<Hash>:: Rules for the filter (see below).
  #
  # ==== Options (rule)
  # :if<Array>:: Optional conditions that must be met for the filter to fire.
  # :unless<Array>::
  #   Optional conditions that must not be met for the filter to fire.
  #
  # ==== Returns
  # Boolean:: True if the conditions are met.
  def _filter_condition_met?(rule)
    # Both:
    # * no :if or the if condition evaluates to true
    # * no :unless or the unless condition evaluates to false
    (!rule.key?(:if) || _evaluate_condition(rule[:if])) &&
    (!rule.key?(:unless) || ! _evaluate_condition(rule[:unless]))
  end

  # ==== Parameters
  # condition<Symbol, Proc>:: The condition to evaluate.
  #
  # ==== Raises
  # ArgumentError:: condition not a Symbol or Proc.
  #
  # ==== Returns
  # Boolean:: True if the condition is met.
  #
  # ==== Alternatives
  # If condition is a symbol, it will be send'ed. If it is a Proc it will be
  # called directly with self as an argument.
  def _evaluate_condition(condition)
    case condition
    when Symbol : self.send(condition)
    when Proc : self.instance_eval(&condition)
    else
      raise ArgumentError,
            'Filter condtions need to be either a Symbol or a Proc'
    end
  end

  # ==== Parameters
  # filter<Symbol, Proc>:: The filter to add. Defaults to nil.
  # opts<Hash>::
  #   Filter options (see class documentation under <tt>Filter Options</tt>).
  # &block:: A block to use as a filter if filter is nil.
  #
  # ==== Notes
  # If the filter already exists, its options will be replaced with opts.
  def self.after(filter = nil, opts = {}, &block)
    add_filter(self._after_filters, filter || block, opts)
  end

  # ==== Parameters
  # filter<Symbol, Proc>:: The filter to add. Defaults to nil.
  # opts<Hash>::
  #   Filter options (see class documentation under <tt>Filter Options</tt>).
  # &block:: A block to use as a filter if filter is nil.
  #
  # ==== Notes
  # If the filter already exists, its options will be replaced with opts.
  def self.before(filter = nil, opts = {}, &block)
    add_filter(self._before_filters, filter || block, opts)
  end
     
  # Skip an after filter that has been previously defined (perhaps in a
  # superclass)
  #
  # ==== Parameters
  # filter<Symbol>:: A filter name to skip.
  def self.skip_after(filter)
    skip_filter(self._after_filters, filter)
  end
  
  # Skip a before filter that has been previously defined (perhaps in a
  # superclass).
  #
  # ==== Parameters
  # filter<Symbol>:: A filter name to skip.
  def self.skip_before(filter)
    skip_filter(self._before_filters , filter)
  end  
  
  #---
  # Defaults that can be overridden by plugins, other mixins, or subclasses
  def _filters_halted()   "<html><body><h1>Filter Chain Halted!</h1></body></html>"  end
  
  # ==== Parameters
  # name<~to_sym, Hash>:: The name of the URL to generate.
  # rparams<Hash>:: Parameters for the route generation.
  #
  # ==== Returns
  # String:: The generated URL.
  #
  # ==== Alternatives
  # If a hash is used as the first argument, a default route will be
  # generated based on it and rparams.
  def url(name, rparams = {}, qparams = {})
    unless rparams.is_a?(Hash) || qparams.empty?
      rparams = qparams.merge(:id => rparams)
    end
    uri = Merb::Router.generate(name, rparams,
      { :controller => controller_name,
        :action => action_name,
        :format => params[:format]
      }
    ) 
    uri = Merb::Config[:path_prefix] + uri if Merb::Config[:path_prefix]
    uri
  end
  alias_method :relative_url, :url

  # ==== Parameters
  # name<~to_sym, Hash>:: The name of the URL to generate.
  # rparams<Hash>:: Parameters for the route generation.
  #
  # ==== Returns
  # String:: The generated url with protocol + hostname + URL.
  #
  # ==== Options
  #
  # :protocol and :host options are special: use them to explicitly
  # specify protocol and host of resulting url. If you omit them,
  # protocol and host of request are used.
  #
  # ==== Alternatives
  # If a hash is used as the first argument, a default route will be
  # generated based on it and rparams.
  def absolute_url(name, rparams={})
    # FIXME: arrgh, why request.protocol returns http://?
    # :// is not part of protocol name
    protocol = rparams.delete(:protocol)
    protocol << "://" if protocol
    
    (protocol || request.protocol) +
      (rparams.delete(:host) || request.host) +
      url(name, rparams)
  end

  # Calls the capture method for the selected template engine.
  #
  # ==== Parameters
  # *args:: Arguments to pass to the block.
  # &block:: The template block to call.
  #
  # ==== Returns
  # String:: The output of the block.
  def capture(*args, &block)
    send("capture_#{@_engine}", *args, &block)
  end

  # Calls the concatenate method for the selected template engine.
  #
  # ==== Parameters
  # str<String>:: The string to concatenate to the buffer.
  # binding<Binding>:: The binding to use for the buffer.
  def concat(str, binding)
    send("concat_#{@_engine}", str, binding)
  end

  private
  # ==== Parameters
  # filters<Array[Filter]>:: The filter list that this should be added to.
  # filter<Filter>:: A filter that should be added.
  # opts<Hash>::
  #   Filter options (see class documentation under <tt>Filter Options</tt>).
  #
  # ==== Raises
  # ArgumentError::
  #   Both :only and :exclude, or :if and :unless given, if filter is not a
  #   Symbol, String or Proc, or if an unknown option is passed.
  def self.add_filter(filters, filter, opts={})
    raise(ArgumentError,
      "You can specify either :only or :exclude but 
       not both at the same time for the same filter.") if opts.key?(:only) && opts.key?(:exclude)
       
     raise(ArgumentError,
       "You can specify either :if or :unless but 
        not both at the same time for the same filter.") if opts.key?(:if) && opts.key?(:unless)
        
    opts.each_key do |key| raise(ArgumentError,
      "You can only specify known filter options, #{key} is invalid.") unless FILTER_OPTIONS.include?(key)
    end

    opts = normalize_filters!(opts)
    
    case filter
    when Proc
      # filters with procs created via class methods have identical signature
      # regardless if they handle content differently or not. So procs just
      # get appended
      filters << [filter, opts]
    when Symbol, String
      if existing_filter = filters.find {|f| f.first.to_s[filter.to_s]}
        filters[ filters.index(existing_filter) ] = [filter, opts]
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
  # inheritence hierarchies.
  #
  # ==== Parameters
  # filters<Array[Filter]>:: The filter list that this should be removed from.
  # filter<Filter>:: A filter that should be removed.
  #
  # ==== Raises
  # ArgumentError:: filter not Symbol or String.
  def self.skip_filter(filters, filter)
    raise(ArgumentError, 'You can only skip filters that have a String or Symbol name.') unless
      [Symbol, String].include? filter.class

    Merb.logger.warn("Filter #{filter} was not found in your filter chain.") unless
      filters.reject! {|f| f.first.to_s[filter.to_s] }
  end

  # Ensures that the passed in hash values are always arrays.
  #
  # ==== Parameters
  # opts<Hash>:: Options for the filters (see below).
  #
  # ==== Options (opts)
  # :only<Symbol, Array[Symbol]>:: A list of actions.
  # :exclude<Symbol, Array[Symbol]>:: A list of actions.
  #
  # ==== Examples
  #   normalize_filters!(:only => :new) #=> {:only => [:new]}
  def self.normalize_filters!(opts={})
    opts[:only]     = Array(opts[:only]).map {|x| x.to_s} if opts[:only]
    opts[:exclude]  = Array(opts[:exclude]).map {|x| x.to_s} if opts[:exclude]
    return opts
  end

  # Attempts to return the partial local variable corresponding to sym.
  #
  # ==== Paramteres
  # sym<Symbol>:: Method name.
  # *arg:: Arguments to pass to the method.
  # &blk:: A block to pass to the method.
  def method_missing(sym, *args, &blk)
    return @_merb_partial_locals[sym] if @_merb_partial_locals && @_merb_partial_locals.key?(sym)
    super
  end  
end
