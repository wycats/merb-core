# Note that the over-use of "_" in Controller methods is to avoid collisions
# with helpers, which will be pulled directly into controllers from now on.
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
#   before :authorize, :unless => logged_in?  
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
# ==== Filter Options (.before, .after, .add_filter, .if, .unless)
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
# ==== Types (shortcuts for use in this file)
# Filter:: <Array[Symbol, (Symbol, String, Proc)]>
class Merb::AbstractController
  include Merb::RenderMixin
  include Merb::InlineTemplates
  
  class_inheritable_accessor :_before_filters, :_after_filters, :_layout, :_template_root

  # ==== Returns
  # String:: The controller name in path form, e.g. "admin/items".
  #---
  # @public
  def self.controller_name() @controller_name ||= self.name.to_const_path end

  # ==== Returns
  # String:: The controller name in path form, e.g. "admin/items".
  def controller_name()      self.class.controller_name                   end

  self._before_filters, self._after_filters = [], []
  
  # This is called after the controller is instantiated to figure out where to
  # for templates under the _template_root. Override this to define a new
  # structure for your app.
  #
  # ==== Parameters
  # action<~to_s>:: The controller action.
  # type<~to_s>:: The content type. Defaults to nil.
  # controller<~to_s>::
  #   The name of the controller. Defaults to controller_name.
  #
  #
  # ==== Returns
  # String:: 
  #   Indicating where to look for the template for the current controller,
  #   action, and content-type.
  #
  # ==== Note
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
  def _template_location(action, type = nil, controller = controller_name)
    "#{controller}/#{action}"
  end

  # ==== Returns
  # roots<Array[Array]>::
  #   Template roots as pairs of template root path and template location
  #   method.
  def self._template_roots
    read_inheritable_attribute(:template_roots) || 
    write_inheritable_attribute(:template_roots, [[self._template_root, :_template_location]])
  end

  # ==== Parameters
  # roots<Array[Array]>::
  #   Template roots as pairs of template root path and template location
  #   method.
  def self._template_roots=(roots)
    write_inheritable_attribute(:template_roots, roots)
  end
  
  cattr_accessor :_abstract_subclasses, :_template_path_cache
  #---
  # We're using abstract_subclasses so that Merb::Controller can have its
  # own subclasses. We're using a Set so we don't have to worry about
  # uniqueness.
  self._abstract_subclasses = Set.new

  # ==== Returns
  # Set:: The subclasses.
  def self.subclasses_list() _abstract_subclasses end
  
  class << self
    # ==== Parameters
    # klass<Merb::AbstractController>::
    #   The controller that is being inherited from Merb::AbstractController
    def inherited(klass)
      _abstract_subclasses << klass.to_s  
      Object.make_module "Merb::#{klass}Helper" unless klass.to_s =~ /^Merb::/
      klass.class_eval <<-HERE
        include Object.full_const_get("Merb::#{klass}Helper") rescue nil
      HERE
      super
    end
    
    # ==== Parameters
    # layout<~to_s>:: The layout that should be used for this class
    # 
    # ==== Returns
    # ~to_s:: The layout that was passed in
    def layout(layout)
      self._layout = layout
    end
  end
  
  attr_accessor :_benchmarks, :_thrown_content

  #---
  # @semipublic
  attr_accessor :body
  
  attr_accessor :action_name
  
  # ==== Parameters
  # *args:: The args are ignored.
  def initialize(*args)
    @_benchmarks = {}
    @_caught_content = {}
    @_template_stack = []
  end
  
  # This will dispatch the request, calling setup_session and finalize_session
  # 
  # ==== Parameters
  # action<~to_s>::
  #   The action to dispatch to. This will be #send'ed in _call_action.
  #   Defaults to :to_s.
  #
  # ==== Raises
  # MerbControllerError:: Invalid body content caught.
  def _dispatch(action=:to_s)
    setup_session
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
    when Proc                     then caught.call(self)
    else
      raise MerbControllerError, "The before filter chain is broken dude. wtf?"
    end
    start = Time.now
    _call_filters(_after_filters) 
    @_benchmarks[:after_filters_time] = Time.now - start if _after_filters
    finalize_session
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
        when Symbol, String then send(filter)
        when Proc           then self.instance_eval(&filter)
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
    when Proc : condition.call(self)
    else
      raise ArgumentError,
            'Filter condtions need to be either a Symbol or a Proc'
    end
  end

  # ==== Parameters
  # filter<Symbol, Proc>:: The filter to add. Defaults to nil.
  # opts<Hash>::
  #   Filter options (see class documentation under <tt>Filter Options</tt>).
  # &block:: Currently ignored.
  #
  # ==== Note
  # If the filter already exists, its options will be replaced with opts.
  def self.after(filter = nil, opts = {}, &block)
    add_filter(self._after_filters, filter, opts)
  end

  # ==== Parameters
  # filter<Symbol, Proc>:: The filter to add. Defaults to nil.
  # opts<Hash>::
  #   Filter options (see class documentation under <tt>Filter Options</tt>).
  # &block:: A block to use as a filter if filter is nil.
  #
  # ==== Note
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

  # Method stub for setting up the session. This will be overriden by session
  # modules.
  def setup_session()    end

  # Method stub for finalizing up the session. This will be overriden by
  # session modules.
  def finalize_session() end  

  # Stub so content-type support in RenderMixin doesn't throw errors
  attr_accessor :content_type
  
  # Handles the template cache (which is used by BootLoader to cache the list
  # of all templates).
  #
  # ==== Parameters
  # template<String>::
  #   The full path to a template to add to the list of available templates
  def self.add_path_to_template_cache(template)
    return false if template.blank? || template.split("/").last.split(".").size != 3
    key = template.match(/(.*)\.(.*)$/)[1]
    self._template_path_cache[key] = template
  end
  
  # Resets the template_path_cache to an empty hash
  def self.reset_template_path_cache!
    self._template_path_cache = {}
  end  
  
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
  def url(name, rparams={})
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
  # ==== Alternatives
  # If a hash is used as the first argument, a default route will be
  # generated based on it and rparams.
  def absolute_url(name, rparams={})
    request.protocol + request.host + url(name, rparams)
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
  #   Both :only and :exclude, or :if and :unless given, or filter is not a
  #   Symbol, String or Proc.
  def self.add_filter(filters, filter, opts={})
    raise(ArgumentError,
      "You can specify either :only or :exclude but 
       not both at the same time for the same filter.") if opts.key?(:only) && opts.key?(:exclude)
       
     raise(ArgumentError,
       "You can specify either :if or :unless but 
        not both at the same time for the same filter.") if opts.key?(:if) && opts.key?(:unless)

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
