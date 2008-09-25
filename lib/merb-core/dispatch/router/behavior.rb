module Merb
  
  class Router
    
    class Behavior

      class Error < StandardError; end;
      
      # Proxy catches any methods and proxies them to the current behavior.
      # This allows building routes without constantly having to catching the
      # yielded behavior object
      # ---
      # @private
      class Proxy #:nodoc:
        # Undefine as many methods as possible so that everything can be proxied
        # along to the behavior
        instance_methods.each { |m| undef_method m unless %w[ __id__ __send__ class kind_of? respond_to? assert_kind_of should should_not instance_variable_set instance_variable_get instance_eval].include?(m) }
        
        def initialize
          @behaviors = []
        end
        
        def push(behavior)
          @behaviors.push(behavior)
        end
        
        def pop
          @behaviors.pop
        end
        
        # Rake does some stuff with methods in the global namespace, so if I don't
        # explicitly define the Behavior methods to proxy here (specifically namespace)
        # Rake's methods take precedence.
        %w(
          match to with register default defaults options option namespace identify
          default_routes defer_to name full_name fixatable redirect capture
        ).each do |method|
          class_eval %{
            def #{method}(*args, &block)
              @behaviors.last.#{method}(*args, &block)
            end
          }
        end
        
        def respond_to?(*args)
          super || @behaviors.last.respond_to?(*args)
        end
        
      private
      
        def method_missing(method, *args, &block)
          behavior = @behaviors.last
          
          if behavior.respond_to?(method)
            behavior.send(method, *args, &block)
          else
            super
          end
        end
      end

      # Behavior objects are used for the Route building DSL. Each object keeps
      # track of the current definitions for the level at which it is defined.
      # Each time a method is called on a Behavior object that accepts a block,
      # a new instance of the Behavior class is created.
      #
      # ==== Parameters
      #
      # proxy<Proxy>::
      #   This is the object initialized by Merb::Router.prepare that tracks the
      #   current Behavior object stack so that Behavior methods can be called
      #   without explicitly calling them on an instance of Behavior.
      # conditions<Hash>::
      #   The initial route conditions. See #match.
      # params<Hash>::
      #   The initial route parameters. See #to.
      # defaults<Hash>::
      #   The initial route default parameters. See #defaults.
      # options<Hash>::
      #   The initial route options. See #options.
      #
      # ==== Returns
      # Behavior:: The initialized Behavior object
      #---
      # @private
      def initialize(proxy = nil, conditions = {}, params = {}, defaults = {}, identifiers = {}, options = {}) #:nodoc:
        @proxy       = proxy
        @conditions  = conditions
        @params      = params
        @defaults    = defaults
        @identifiers = identifiers
        @options     = options

        stringify_condition_values
      end

      # Defines the +conditions+ that are required to match a Request. Each
      # +condition+ is applied to a method of the Request object. Conditions
      # can also be applied to segments of the +path+.
      #
      # If #match is passed a block, it will create a new route scope with
      # the conditions passed to it and yield to the block such that all
      # routes that are defined in the block have the conditions applied
      # to them.
      #
      # ==== Parameters
      #
      # path<String, Regexp>::
      #   The pattern against which Merb::Request path is matched.
      #
      #   When +path+ is a String, any substring that is wrapped in parenthesis
      #   is considered optional and any segment that begins with a colon, ex.:
      #   ":login", defines both a capture and a named param. Extra conditions
      #   can then be applied each named param individually.
      #
      #   When +path+ is a Regexp, the pattern is left untouched and the
      #   Merb::Request path is matched against it as is.
      #
      #   +path+ is optional.
      #
      # conditions<Hash>::
      #   Additional conditions that the request must meet in order to match.
      #   The keys must be the names of previously defined path segments or
      #   be methods that the Merb::Request instance will respond to.  The
      #   value is the string or regexp that matched the returned value.
      #   Conditions are inherited by child routes.
      #
      # &block::
      #   All routes defined in the block will be scoped to the conditions
      #   defined by the #match method.
      #
      # ==== Block parameters
      # r<Behavior>:: +optional+ - The match behavior object.
      #
      # ==== Returns
      # Behavior::
      #   A new instance of Behavior with the specified path and conditions.
      #
      # +Tip+: When nesting always make sure the most inner sub-match registers
      # a Route and doesn't just returns new Behaviors.
      #
      # ==== Examples
      #
      #   # registers /foo/bar to controller => "foo", :action => "bar"
      #   # and /foo/baz to controller => "foo", :action => "baz"
      #   match("/foo") do
      #     match("/bar").to(:controller => "foo", :action => "bar")
      #     match("/baz").to(:controller => "foo", :action => "caz")
      #   end
      #
      #   # Checks the format of the segments against the specified Regexp
      #   match("/:string/:number", :string => /[a-z]+/, :number => /\d+/).
      #     to(:controller => "string_or_numbers")
      #
      #   # Equivalent to the default_route
      #   match("/:controller(/:action(:id))(.:format)").register
      #
      #   #match only if the browser string contains MSIE or Gecko
      #   match("/foo", :user_agent => /(MSIE|Gecko)/ )
      #        .to(:controller => 'foo', :action => 'popular')
      #
      #   # Route GET and POST requests to different actions (see also #resources)
      #   r.match('/foo', :method => :get).to(:action => 'show')
      #   r.match('/foo', :method => :post).to(:action => 'create')
      #
      #   # match also takes regular expressions
      #
      #   r.match(%r[/account/([a-z]{4,6})]).to(:controller => "account",
      #      :action => "show", :id => "[1]")
      #
      #   r.match(%r{/?(en|es|fr|be|nl)?}).to(:language => "[1]") do
      #     match("/guides/:action/:id").to(:controller => "tour_guides")
      #   end
      #---
      # @public
      def match(path = {}, conditions = {}, &block)
        path, conditions = path[:path], path if Hash === path
        conditions[:path] = merge_paths(path)

        raise Error, "The route has already been committed. Further conditions cannot be specified" if @route

        behavior = Behavior.new(@proxy, @conditions.merge(conditions), @params, @defaults, @identifiers, @options)
        with_behavior_context(behavior, &block)
      end
      
      # Creates a Route from one or more Behavior objects, unless a +block+ is
      # passed in.
      #
      # ==== Parameters
      # params<Hash>:: The parameters the route maps to.
      #
      # &block::
      #   All routes defined in the block will be scoped to the params
      #   defined by the #to method.
      #
      # ==== Block parameters
      # r<Behavior>:: +optional+ - The to behavior object.
      #
      # ==== Returns
      # Route:: It registers a new route and returns it.
      #
      # ==== Examples
      #   match('/:controller/:id).to(:action => 'show')
      #
      #   to(:controller => 'simple') do
      #     match('/test').to(:action => 'index')
      #     match('/other').to(:action => 'other')
      #   end
      #---
      # @public
      def to(params = {}, &block)
        raise Error, "The route has already been committed. Further params cannot be specified" if @route

        behavior = Behavior.new(@proxy, @conditions, @params.merge(params), @defaults, @identifiers, @options)
        
        if block_given?
          with_behavior_context(behavior, &block)
        else
          behavior.to_route
        end
      end
      
      # Equivalent of #to. Allows for some nicer syntax when scoping blocks
      # --- Ex:
      # Merb::Router.prepare do
      #   with(:controller => "users") do
      #     match("/signup").to(:action => "signup")
      #     match("/login").to(:action => "login")
      #     match("/logout").to(:action => "logout")
      #   end
      # end
      alias_method :with, :to
      
      # Equivalent of #to. Allows for nicer syntax when registering routes with no params
      # --- Ex:
      # Merb::Router.prepare do
      #   match("/:controller(/:action(/:id))(.:format)").register
      # end
      #
      alias_method :register, :to
      
      # Sets default values for route parameters. If no value for the key
      # can be extracted from the request, then the value provided here
      # will be used.
      #
      # ==== Parameters
      # defaults<Hash>::
      #   The default values for named segments.
      #
      # &block::
      #   All routes defined in the block will be scoped to the defaults defined
      #   by the #default method.
      #
      # ==== Block parameters
      # r<Behavior>:: +optional+ - The defaults behavior object.
      # ---
      # @public
      def default(defaults = {}, &block)
        behavior = Behavior.new(@proxy, @conditions, @params, @defaults.merge(defaults), @identifiers, @options)
        with_behavior_context(behavior, &block)
      end
      
      alias_method :defaults, :default
      
      # Allows the fine tuning of certain router options.
      #
      # ==== Parameters
      # options<Hash>::
      #   The options to set for all routes defined in the scope. The currently
      #   supported options are:
      #   * :controller_prefix - The module that the controller is included in.
      #   * :name_prefix       - The prefix added to all routes named with #name
      #
      # &block::
      #   All routes defined in the block will be scoped to the options defined
      #   by the #options method.
      #
      # ==== Block parameters
      # r<Behavior>:: The options behavior object. This is optional
      #
      # ==== Examples
      #   # If :group is not matched in the path, it will be "registered" instead
      #   # of nil.
      #   match("/users(/:group)").default(:group => "registered")
      # ---
      # @public
      def options(opts = {}, &block)
        options = @options.dup

        opts.each_pair do |key, value|
          options[key] = (options[key] || []) + [value.freeze] if value
        end

        behavior = Behavior.new(@proxy, @conditions, @params, @defaults, @identifiers, options)
        with_behavior_context(behavior, &block)
      end
      
      alias_method :options, :options
      
      # Creates a namespace for a route. This way you can have logical
      # separation to your routes.
      #
      # ==== Parameters
      # name_or_path<String, Symbol>::
      #   The name or path of the namespace.
      #
      # options<Hash>::
      #   Optional hash, set :path if you want to override what appears on the url
      #
      # &block::
      #   All routes defined in the block will be scoped to the namespace defined
      #   by the #namespace method.
      #
      # ==== Block parameters
      # r<Behavior>:: The namespace behavior object. This is optional
      #
      # ==== Examples
      #   namespace :admin do
      #     resources :accounts
      #     resource :email
      #   end
      #
      #   # /super_admin/accounts
      #   namespace(:admin, :path=>"super_admin") do
      #     resources :accounts
      #   end
      # ---
      # @public
      def namespace(name_or_path, opts = {}, &block)
        name = name_or_path.to_s # We don't want this modified ever
        path = opts.has_key?(:path) ? opts[:path] : name

        raise Error, "The route has already been committed. Further options cannot be specified" if @route

        # option keys could be nil
        opts[:controller_prefix] = name unless opts.has_key?(:controller_prefix)
        opts[:name_prefix]       = name unless opts.has_key?(:name_prefix)

        behavior = self
        behavior = behavior.match("/#{path}") unless path.nil? || path.empty?
        behavior.options(opts, &block)
      end
      
      # Sets a method for instances of specified Classes to be called before
      # insertion into a route. This is useful when using models and want a
      # specific method to be called on it (For example, for ActiveRecord::Base
      # it would be #to_param).
      #
      # The default method called on objects is #to_s.
      #
      # ==== Paramters
      # identifiers<Hash>::
      #   The keys are Classes and the values are the method that instances of the specified
      #   class should have called on.
      #
      # &block::
      #   All routes defined in the block will be call the specified methods during
      #   generation.
      #
      # ==== Block parameters
      # r<Behavior>:: The identify behavior object. This is optional
      # ---
      # @public
      def identify(identifiers = {}, &block)
        identifiers = if Hash === identifiers
          @identifiers.merge(identifiers)
        else
          { Object => identifiers }
        end
        
        behavior = Behavior.new(@proxy, @conditions, @params, @defaults, identifiers.freeze, @options)
        with_behavior_context(behavior, &block)
      end
      
      # Creates the most common routes /:controller/:action/:id.format when
      # called with no arguments. You can pass a hash or a block to add parameters
      # or override the default behavior.
      #
      # ==== Parameters
      # params<Hash>::
      #   This optional hash can be used to augment the default settings
      #
      # &block::
      #   When passing a block a new behavior is yielded and more refinement is
      #   possible.
      #
      # ==== Returns
      # Route:: the default route
      #
      # ==== Examples
      #
      #   # Passing an extra parameter "mode" to all matches
      #   r.default_routes :mode => "default"
      #
      #   # specifying exceptions within a block
      #   r.default_routes do |nr|
      #     nr.defer_to do |request, params|
      #       nr.match(:protocol => "http://").to(:controller => "login",
      #         :action => "new") if request.env["REQUEST_URI"] =~ /\/private\//
      #     end
      #   end
      #---
      # @public
      def default_routes(params = {}, &block)
        match("/:controller(/:action(/:id))(.:format)").to(params, &block).name(:default)
      end
      
      # Takes a block and stores it for deferred conditional routes. The block
      # takes the +request+ object and the +params+ hash as parameters.
      #
      # ==== Parameters
      # params<Hash>:: Parameters and conditions associated with this behavior.
      # &conditional_block::
      #   A block with the conditions to be met for the behavior to take
      #   effect.
      #
      # ==== Returns
      # Route :: The default route.
      #
      # ==== Examples
      #   r.defer_to do |request, params|
      #     params.merge :controller => 'here',
      #       :action => 'there' if request.xhr?
      #   end
      #---
      # @public
      def defer_to(params = {}, &conditional_block)
        to_route(params, &conditional_block)
      end
      
      # Names this route in Router. Name must be a Symbol.
      #
      # ==== Parameters
      # symbol<Symbol>:: The name of the route.
      #
      # ==== Raises
      # ArgumentError:: symbol is not a Symbol.
      def name(prefix, name = nil)
        unless name
          name, prefix = prefix, nil
        end

        full_name([prefix, @options[:name_prefix], name].flatten.compact.join('_'))
      end

      # Names this route in Router. Name must be a Symbol. The current
      # name_prefix is ignored.
      #
      # ==== Parameters
      # symbol<Symbol>:: The name of the route.
      #
      # ==== Raises
      # ArgumentError:: symbol is not a Symbol.
      def full_name(name)
        if @route
          @route.name = name
          self
        else
          register.full_name(name)
        end
      end
      
      # ==== Parameters
      # enabled<Boolean>:: True enables fixation on the route.
      def fixatable(enable = true)
        @route.fixation = enable
        self
      end

      def redirect(url, permanent = true)
        raise Error, "The route has already been committed." if @route

        status = permanent ? 301 : 302
        @route = Route.new(@conditions, {:url => url.freeze, :status => status.freeze}, :redirects => true)
        @route.register
        self
      end
      
      # Capture any new routes that have been added within the block.
      #
      # This utility method lets you track routes that have been added;
      # it doesn't affect how/which routes are added.
      #
      # &block:: A context in which routes are generated.
      def capture(&block)
        captured_routes = {}
        name_prefix     = [@options[:name_prefix]].flatten.compact.map { |p| "#{p}_"}
        current_names   = Merb::Router.named_routes.keys
        
        behavior = Behavior.new(@proxy, @conditions, @params, @defaults, @identifiers, @options)
        with_behavior_context(behavior, &block)
        
        Merb::Router.named_routes.reject { |k,v| current_names.include?(k) }.each do |name, route|
          name = route.name.to_s.sub("#{name_prefix}", '').to_sym unless name_prefix.empty?
          captured_routes[name] = route
        end
        
        captured_routes
      end
      
      # So that Router can have a default route
      # ---
      # @private
      def with_proxy(&block) #:nodoc:
        proxy = Proxy.new
        proxy.push Behavior.new(proxy, @conditions, @params, @defaults, @identifiers, @options)
        proxy.instance_eval(&block)
        proxy
      end
      
    protected
      
      def to_route(params = {}, &conditional_block) # :nodoc:
        
        raise Error, "The route has already been committed." if @route

        params     = @params.merge(params)
        controller = params[:controller]

        if prefixes = @options[:controller_prefix]
          controller ||= ":controller"
          
          prefixes.reverse_each do |prefix|
            break if controller =~ %r{^/(.*)} && controller = $1
            controller = "#{prefix}/#{controller}"
          end
        end
        
        params.merge!(:controller => controller.to_s.gsub(%r{^/}, '')) if controller
        
        # Sorts the identifiers so that modules that are at the bottom of the
        # inheritance chain come first (more specific modules first). Object
        # should always be last.
        identifiers = @identifiers.sort { |(first,_),(sec,_)| first <=> sec || 1 }
        
        @route = Route.new(@conditions.dup, params, :defaults => @defaults.dup, :identifiers => identifiers, &conditional_block)
        @route.register
        self
      end

    private
    
      def stringify_condition_values # :nodoc:
        @conditions.each do |key, value|
          unless value.nil? || Regexp === value || Array === value
            @conditions[key] = value.to_s
          end
        end
      end
    
      def with_behavior_context(behavior, &block) # :nodoc:
        if block_given?
          @proxy.push(behavior)
          retval = yield(behavior)
          @proxy.pop
        end
        behavior
      end

      def merge_paths(path) # :nodoc:
        [@conditions[:path], path.freeze].flatten.compact
      end

    end
  end
end