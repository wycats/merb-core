module Merb

  class Router

    # The Behavior class is an interim route-building class that ties
    # pattern-matching +conditions+ to output parameters, +params+.
    #---
    # @public
    class Behavior
      attr_reader :placeholders, :conditions, :params, :redirect_url, :redirect_status
      attr_accessor :parent
      @@parent_resources = []
      class << self

        # ==== Parameters
        # string<String>:: The string in which to count parentheses.
        # pos<Fixnum>:: The last character for counting.
        #
        # ==== Returns
        # Fixnum::
        #   The number of open parentheses in string, up to and including pos.
        def count_parens_up_to(string, pos)
          string[0..pos].gsub(/[^\(]/, '').size
        end

        # ==== Parameters
        # string1<String>:: The string to concatenate with.
        # string2<String>:: The string to concatenate.
        #
        # ==== Returns
        # String:: the concatenated string with regexp end caps removed.
        def concat_without_endcaps(string1, string2)
          return nil if !string1 and !string2
          return string1 if string2.nil?
          return string2 if string1.nil?
          s1 = string1[-1] == ?$ ? string1[0..-2] : string1
          s2 = string2[0] == ?^ ? string2[1..-1] : string2
          s1 + s2
        end

        # ==== Parameters
        # arr<Array>:: The array to convert to a code string.
        #
        # ==== Returns
        # String::
        #   The arr's elements converted to string and joined with " + ", with
        #   any string elements surrounded by quotes.
        def array_to_code(arr)
          code = ''
          arr.each_with_index do |part, i|
            code << ' + ' if i > 0
            case part
            when Symbol
              code << part.to_s
            when String
              code << %{"#{part}"}
            else
              raise "Don't know how to compile array part: #{part.class} [#{i}]"
            end
          end
          code
        end
      end # class << self

      # ==== Parameters
      # conditions<Hash>::
      #   Conditions to be met for this behavior to take effect.
      # params<Hash>::
      #   Hash describing the course action to take (Behavior) when the
      #   conditions match. The values of the +params+ keys must be Strings.
      # parent<Behavior, Nil>::
      #   The parent of this Behavior. Defaults to nil.
      def initialize(conditions = {}, params = {}, parent = nil)
        # Must wait until after deducing placeholders to set @params !
        @conditions, @params, @parent = conditions, {}, parent
        @placeholders = {}
        stringify_conditions
        copy_original_conditions
        deduce_placeholders
        @params.merge! params
      end

      # Register a new route.
      #
      # ==== Parameters
      # path<String, Regex>:: The url path to match
      # params<Hash>:: The parameters the new routes maps to.
      #
      # ==== Returns
      # Route:: The resulting Route.
      #---
      # @public
      def add(path, params = {})
        match(path).to(params)
      end

      # Matches a +path+ and any number of optional request methods as
      # conditions of a route. Alternatively, +path+ can be a hash of
      # conditions, in which case +conditions+ is ignored.
      #
      # ==== Parameters
      #
      # path<String, Regexp>::
      #   When passing a string as +path+ you're defining a literal definition
      #   for your route. Using a colon, ex.: ":login", defines both a capture
      #   and a named param.
      #   When passing a regular expression you can define captures explicitly
      #   within the regular expression syntax.
      #   +path+ is optional.
      # conditions<Hash>::
      #   Additional conditions that the request must meet in order to match.
      #   The keys must be methods that the Merb::Request instance will respond
      #   to.  The value is the string or regexp that matched the returned value.
      #   Conditions are inherited by child routes.
      #
      #   The following have special meaning:
      #   * :method -- Limit this match based on the request method. (GET,
      #     POST, PUT, DELETE)
      #   * :path -- Used internally to maintain URL form information
      #   * :controller and :action -- These can be used here instead of '#to', and
      #     will be inherited in the block.
      #   * :params -- Sets other key/value pairs that are placed in the params
      #     hash. The value must be a hash.
      # &block::
      #   Passes a new instance of a Behavior object into the optional block so
      #   that sub-matching and routes nesting may occur.
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
      #   r.match "/foo", :controller=>"foo" do |f|
      #     f.match("/bar").to(:action => "bar")
      #     f.match("/baz").to(:action => "caz")
      #   end
      #
      #   #match only if the browser string contains MSIE or Gecko
      #   r.match ('/foo', :user_agent => /(MSIE|Gecko)/ )
      #        .to({:controller=>'foo', :action=>'popular')
      #
      #   # Route GET and POST requests to different actions (see also #resources)
      #   r.match('/foo', :method=>:get).to(:action=>'show')
      #   r.match('/foo', :method=>:post).to(:action=>'create')
      #
      #   # match also takes regular expressions
      #
      #   r.match(%r[/account/([a-z]{4,6})]).to(:controller => "account",
      #      :action => "show", :id => "[1]")
      #
      #   r.match(/\/?(en|es|fr|be|nl)?/).to(:language => "[1]") do |l|
      #     l.match("/guides/:action/:id").to(:controller => "tour_guides")
      #   end
      #---
      # @public
      def match(path = '', conditions = {}, &block)
        if path.is_a? Hash
          conditions = path
        else
          conditions[:path] = path
        end
        match_without_path(conditions, &block)
      end

      # Generates a new child behavior without the path if the path matches
      # an empty string. Yields the new behavior to a block.
      #
      # ==== Parameters
      # conditions<Hash>:: Optional conditions to pass to the new route.
      #
      # ==== Block parameters
      # new_behavior<Behavior>:: The child behavior.
      #
      # ==== Returns
      # Behavior:: The new behavior.
      def match_without_path(conditions = {})
        params = conditions.delete(:params) || {} #parents params will be merged  in Route#new
        params[:controller] = conditions.delete(:controller) if conditions[:controller]
        params[:action] = conditions.delete(:action) if conditions[:action]
        new_behavior = self.class.new(conditions, params, self)
        yield new_behavior if block_given?
        new_behavior
      end

      # ==== Parameters
      # params<Hash>:: Optional additional parameters for generating the route.
      # &conditional_block:: A conditional block to be passed to Route.new.
      #
      # ==== Returns
      # Route:: A new route based on this behavior.
      def to_route(params = {}, &conditional_block)
        @params.merge! params
        Route.new compiled_conditions, compiled_params, self, &conditional_block
      end

      # Combines common case of match being used with
      # to({}).
      #
      # ==== Returns
      # <Route>:: route that uses params from named path segments.
      #
      # ==== Examples
      # r.match!("/api/:token/:controller/:action/:id")
      #
      # is the same thing as
      #
      # r.match!("/api/:token/:controller/:action/:id").to({})
      def match!(path = '', conditions = {}, &block)
        self.match(path, conditions, &block).to({})
      end

      # Creates a Route from one or more Behavior objects, unless a +block+ is
      # passed in.
      #
      # ==== Parameters
      # params<Hash>:: The parameters the route maps to.
      # &block::
      #   Optional block. A new Behavior object is yielded and further #to
      #   operations may be called in the block.
      #
      # ==== Block parameters
      # new_behavior<Behavior>:: The child behavior.
      #
      # ==== Returns
      # Route:: It registers a new route and returns it.
      #
      # ==== Examples
      #   r.match('/:controller/:id).to(:action => 'show')
      #
      #   r.to :controller => 'simple' do |s|
      #     s.match('/test').to(:action => 'index')
      #     s.match('/other').to(:action => 'other')
      #   end
      #---
      # @public
      def to(params = {}, &block)
        if block_given?
          new_behavior = self.class.new({}, params, self)
          yield new_behavior if block_given?
          new_behavior
        else
          to_route(params).register
        end
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
        to_route(params, &conditional_block).register
      end

      # Creates the most common routes /:controller/:action/:id.format when
      # called with no arguments.
      # You can pass a hash or a block to add parameters or override the default
      # behavior.
      #
      # ==== Parameters
      # params<Hash>::
      #   This optional hash can be used to augment the default settings
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
        match(%r{/:controller(/:action(/:id)?)?(\.:format)?}).to(params, &block)
      end

      # Creates a namespace for a route. This way you can have logical
      # separation to your routes.
      #
      # ==== Parameters
      # name_or_path<String, Symbol>:: The name or path of the namespace.
      # options<Hash>:: Optional hash, set :path if you want to override what appears on the url
      # &block::
      #   A new Behavior instance is yielded in the block for nested resources.
      #
      # ==== Block parameters
      # r<Behavior>:: The namespace behavior object.
      #
      # ==== Examples
      #   r.namespace :admin do |admin|
      #     admin.resources :accounts
      #     admin.resource :email
      #   end
      #
      #   # /super_admin/accounts
      #   r.namespace(:admin, :path=>"super_admin") do |admin|
      #     admin.resources :accounts
      #   end
      #---
      # @public
      def namespace(name_or_path, options={}, &block)
        path = options[:path] || name_or_path.to_s
        (path.empty? ? self : match("/#{path}")).to(:namespace => name_or_path.to_s) do |r|
          yield r
        end
      end

      # Behavior#+resources+ is a route helper for defining a collection of
      # RESTful resources. It yields to a block for child routes.
      #
      # ==== Parameters
      # name<String, Symbol>:: The name of the resources
      # options<Hash>::
      #   Ovverides and parameters to be associated with the route
      #
      # ==== Options (options)
      # :namespace<~to_s>: The namespace for this route.
      # :name_prefix<~to_s>:
      #   A prefix for the named routes. If a namespace is passed and there
      #   isn't a name prefix, the namespace will become the prefix.
      # :controller<~to_s>: The controller for this route
      # :collection<~to_s>: Special settings for the collections routes
      # :member<Hash>:
      #   Special settings and resources related to a specific member of this
      #   resource.
      # :keys<Array>:
      #   A list of the keys to be used instead of :id with the resource in the order of the url.
      #
      # ==== Block parameters
      # next_level<Behavior>:: The child behavior.
      #
      # ==== Returns
      # Array::
      #   Routes which will define the specified RESTful collection of resources
      #
      # ==== Examples
      #
      #  r.resources :posts # will result in the typical RESTful CRUD
      #    # lists resources
      #    # GET     /posts/?(\.:format)?      :action => "index"
      #    # GET     /posts/index(\.:format)?  :action => "index"
      #
      #    # shows new resource form
      #    # GET     /posts/new                :action => "new"
      #
      #    # creates resource
      #    # POST    /posts/?(\.:format)?,     :action => "create"
      #
      #    # shows resource
      #    # GET     /posts/:id(\.:format)?    :action => "show"
      #
      #    # shows edit form
      #    # GET     /posts/:id/edit        :action => "edit"
      #
      #    # updates resource
      #    # PUT     /posts/:id(\.:format)?    :action => "update"
      #
      #    # shows deletion confirmation page
      #    # GET     /posts/:id/delete      :action => "delete"
      #
      #    # destroys resources
      #    # DELETE  /posts/:id(\.:format)?    :action => "destroy"
      #
      #  # Nesting resources
      #  r.resources :posts do |posts|
      #    posts.resources :comments
      #  end
      #---
      # @public
      def resources(name, options = {})
        namespace = options[:namespace] || merged_params[:namespace]

        next_level = match "/#{name}"

        name_prefix = options.delete :name_prefix
        matched_keys =  options[:keys] ? options.delete(:keys).map{|k| ":#{k}"}.join("/")  : ":id"

        if name_prefix.nil? && !namespace.nil?
          name_prefix = namespace_to_name_prefix namespace
        end

        unless @@parent_resources.empty?
          parent_resource = namespace_to_name_prefix @@parent_resources.join('_')
        end

        options[:controller] ||= merged_params[:controller] || name.to_s

        singular = name.to_s.singularize

        route_plural_name   = "#{name_prefix}#{parent_resource}#{name}"
        route_singular_name = "#{name_prefix}#{parent_resource}#{singular}"

        behaviors = []

        if member = options.delete(:member)
          member.each_pair do |action, methods|
            behaviors << Behavior.new(
            { :path => %r{^/#{matched_keys}/#{action}(\.:format)?$}, :method => /^(#{[methods].flatten * '|'})$/ },
            { :action => action.to_s }, next_level
            )
            next_level.match("/#{matched_keys}/#{action}").to_route.name(:"#{action}_#{route_singular_name}")
          end
        end

        if collection = options.delete(:collection)
          collection.each_pair do |action, methods|
            behaviors << Behavior.new(
            { :path => %r{^/#{action}(\.:format)?$}, :method => /^(#{[methods].flatten * '|'})$/ },
            { :action => action.to_s }, next_level
            )
            next_level.match("/#{action}").to_route.name(:"#{action}_#{route_plural_name}")
          end
        end

        routes = many_behaviors_to(behaviors + next_level.send(:resources_behaviors, matched_keys), options)



        # Add names to some routes
        [['', :"#{route_plural_name}"],
        ["/#{matched_keys}", :"#{route_singular_name}"],
        ['/new', :"new_#{route_singular_name}"],
        ["/#{matched_keys}/edit", :"edit_#{route_singular_name}"],
        ["/#{matched_keys}/delete", :"delete_#{route_singular_name}"]
        ].each do |path,name|
          next_level.match(path).to_route.name(name)
        end


        parent_keys = (matched_keys == ":id") ? ":#{singular}_id" : matched_keys
        if block_given?
          @@parent_resources.push(singular)
          yield next_level.match("/#{parent_keys}")
          @@parent_resources.pop
        end

        routes
      end

      # Behavior#+resource+ is a route helper for defining a singular RESTful
      # resource. It yields to a block for child routes.
      #
      # ==== Parameters
      # name<String, Symbol>:: The name of the resource.
      # options<Hash>::
      #   Overides and parameters to be associated with the route.
      #
      # ==== Options (options)
      # :namespace<~to_s>: The namespace for this route.
      # :name_prefix<~to_s>:
      #   A prefix for the named routes. If a namespace is passed and there
      #   isn't a name prefix, the namespace will become the prefix.
      # :controller<~to_s>: The controller for this route
      #
      # ==== Block parameters
      # next_level<Behavior>:: The child behavior.
      #
      # ==== Returns
      # Array:: Routes which define a RESTful single resource.
      #
      # ==== Examples
      #
      #  r.resource :account # will result in the typical RESTful CRUD
      #    # shows new resource form      
      #    # GET     /account/new                :action => "new"
      #
      #    # creates resource      
      #    # POST    /account/?(\.:format)?,     :action => "create"
      #
      #    # shows resource      
      #    # GET     /account/(\.:format)?       :action => "show"
      #
      #    # shows edit form      
      #    # GET     /account//edit           :action => "edit"
      #
      #    # updates resource      
      #    # PUT     /account/(\.:format)?       :action => "update"
      #
      #    # shows deletion confirmation page      
      #    # GET     /account//delete         :action => "delete"
      #
      #    # destroys resources      
      #    # DELETE  /account/(\.:format)?       :action => "destroy"
      #
      # You can optionally pass :namespace and :controller to refine the routing
      # or pass a block to nest resources.
      #
      #   r.resource :account, :namespace => "admin" do |account|
      #     account.resources :preferences, :controller => "settings"
      #   end
      # ---
      # @public
      def resource(name, options = {})
        namespace  = options[:namespace] || merged_params[:namespace]

        next_level = match "/#{name}"

        options[:controller] ||= merged_params[:controller] || name.to_s

        # Do not pass :name_prefix option on to to_resource
        name_prefix = options.delete :name_prefix

        if name_prefix.nil? && !namespace.nil?
          name_prefix = namespace_to_name_prefix namespace
        end

        unless @@parent_resources.empty?
          parent_resource = namespace_to_name_prefix @@parent_resources.join('_')
        end

        routes = next_level.to_resource options

        route_name = "#{name_prefix}#{name}"

        next_level.match('').to_route.name(:"#{route_name}")
        next_level.match('/new').to_route.name(:"new_#{route_name}")
        next_level.match('/edit').to_route.name(:"edit_#{route_name}")
        next_level.match('/delete').to_route.name(:"delete_#{route_name}")

        if block_given?
          @@parent_resources.push(route_name)
          yield next_level
          @@parent_resources.pop
        end

        routes
      end

      # ==== Parameters
      # params<Hash>:: Optional params for generating the RESTful routes.
      # &block:: Optional block for the route generation.
      #
      # ==== Returns
      # Array:: Routes matching the RESTful resource.
      def to_resources(params = {}, &block)
        many_behaviors_to resources_behaviors, params, &block
      end

      # ==== Parameters
      # params<Hash>:: Optional params for generating the RESTful routes.
      # &block:: Optional block for the route generation.
      #
      # ==== Returns
      # Array:: Routes matching the RESTful singular resource.
      def to_resource(params = {}, &block)
        many_behaviors_to resource_behaviors, params, &block
      end

      # ==== Returns
      # Hash::
      #   The original conditions of this behavior merged with the original
      #   conditions of all its ancestors.
      def merged_original_conditions
        if parent.nil?
          @original_conditions
        else
          merged_so_far = parent.merged_original_conditions
          if path = Behavior.concat_without_endcaps(merged_so_far[:path], @original_conditions[:path])
            merged_so_far.merge(@original_conditions).merge(:path => path)
          else
            merged_so_far.merge(@original_conditions)
          end
        end
      end

      # ==== Returns
      # Hash::
      #   The conditions of this behavior merged with the conditions of all its
      #   ancestors.
      def merged_conditions
        if parent.nil?
          @conditions
        else
          merged_so_far = parent.merged_conditions
          if path = Behavior.concat_without_endcaps(merged_so_far[:path], @conditions[:path])
            merged_so_far.merge(@conditions).merge(:path => path)
          else
            merged_so_far.merge(@conditions)
          end
        end
      end

      # ==== Returns
      # Hash::
      #   The params of this behavior merged with the params of all its
      #   ancestors.
      def merged_params
        if parent.nil?
          @params
        else
          parent.merged_params.merge(@params)
        end
      end

      # ==== Returns
      # Hash::
      #   The route placeholders, e.g. :controllers, of this behavior merged
      #   with the placeholders of all its ancestors.
      def merged_placeholders
        placeholders = {}
        (ancestors.reverse + [self]).each do |a|
          a.placeholders.each_pair do |k, pair|
            param, place = pair
            placeholders[k] = [param, place + (param == :path ? a.total_previous_captures : 0)]
          end
        end
        placeholders
      end

      # ==== Returns
      # String:: A human readable form of the behavior.
      def inspect
        "[captures: #{path_captures.inspect}, conditions: #{@original_conditions.inspect}, params: #{@params.inspect}, placeholders: #{@placeholders.inspect}]"
      end

      # ==== Returns
      # Boolean:: True if this behavior has a regexp.
      def regexp?
        @conditions_have_regexp
      end

      def redirect(url, permanent = true)
        @redirects       = true
        @redirect_url    = url
        @redirect_status = permanent ? 301 : 302

        # satisfy route compilation
        self.to({})
      end

      def redirects?
        @redirects
      end
      
      def ancestors
        @ancestors ||= find_ancestors
      end

    protected

      # ==== Parameters
      # name_or_path<~to_s>::
      #   The name or path to convert to a form suitable for a prefix.
      #
      # ==== Returns
      # String:: The prefix.
      def namespace_to_name_prefix(name_or_path)
        name_or_path.to_s.tr('/', '_') + '_'
      end

      # ==== Parameters
      # matched_keys<String>::
      #   The keys to match
      #
      # ==== Returns
      # Array:: Behaviors for a RESTful resource.
      def resources_behaviors(matched_keys = ":id")
        [
          Behavior.new({ :path => %r[^/?(\.:format)?$],     :method => :get },    { :action => "index" },   self),
          Behavior.new({ :path => %r[^/index(\.:format)?$], :method => :get },    { :action => "index" },   self),
          Behavior.new({ :path => %r[^/new$],               :method => :get },    { :action => "new" },     self),
          Behavior.new({ :path => %r[^/?(\.:format)?$],     :method => :post },   { :action => "create" },  self),
          Behavior.new({ :path => %r[^/#{matched_keys}(\.:format)?$],   :method => :get },    { :action => "show" },    self),
          Behavior.new({ :path => %r[^/#{matched_keys}/edit$],       :method => :get },    { :action => "edit" },    self),
          Behavior.new({ :path => %r[^/#{matched_keys}/delete$],     :method => :get },    { :action => "delete" },  self),
          Behavior.new({ :path => %r[^/#{matched_keys}(\.:format)?$],   :method => :put },    { :action => "update" },  self),
          Behavior.new({ :path => %r[^/#{matched_keys}(\.:format)?$],   :method => :delete }, { :action => "destroy" }, self)
        ]
      end

      # ==== Parameters
      # parent<Merb::Router::Behavior>::
      #   The parent behavior for the generated resource behaviors.
      #
      # ==== Returns
      # Array:: Behaviors for a singular RESTful resource.
      def resource_behaviors(parent = self)
        [
          Behavior.new({ :path => %r{^/new$},        :method => :get },    { :action => "new" },     parent),
          Behavior.new({ :path => %r{^/?(\.:format)?$}, :method => :post },   { :action => "create" },  parent),
          Behavior.new({ :path => %r{^/?(\.:format)?$}, :method => :get },    { :action => "show" },    parent),
          Behavior.new({ :path => %r{^/edit$},       :method => :get },    { :action => "edit" },    parent),
          Behavior.new({ :path => %r{^/delete$},     :method => :get },    { :action => "delete" },    parent),
          Behavior.new({ :path => %r{^/?(\.:format)?$}, :method => :put },    { :action => "update" },  parent),
          Behavior.new({ :path => %r{^/?(\.:format)?$}, :method => :delete }, { :action => "destroy" }, parent)
        ]
      end

      # ==== Parameters
      # behaviors<Array>:: The behaviors to create routes from.
      # params<Hash>:: Optional params for the route generation.
      # &conditional_block:: Optional block for the route generation.
      #
      # ==== Returns
      # Array:: The routes matching the behaviors.
      def many_behaviors_to(behaviors, params = {}, &conditional_block)
        behaviors.map { |b| b.to params, &conditional_block }
      end

      # Convert conditions to regular expression string sources for consistency.
      def stringify_conditions
        @conditions_have_regexp = false
        @conditions.each_pair do |k,v|
          # TODO: Other Regexp special chars

          @conditions[k] = case v
          when String,Symbol
            "^#{v.to_s.escape_regexp}$"
          when Regexp
            @conditions_have_regexp = true
            v.source
          end
        end
      end

      # Store the conditions as original conditions.
      def copy_original_conditions
        @original_conditions = {}
        @conditions.each_pair do |key, value|
          @original_conditions[key] = value.dup
        end
        @original_conditions
      end

      # Calculate the behaviors from the conditions and store them.
      def deduce_placeholders
        @conditions.each_pair do |match_key, source|
          while match = SEGMENT_REGEXP.match(source)
            source.sub! SEGMENT_REGEXP, PARENTHETICAL_SEGMENT_STRING
            unless match[2] == ':' # No need to store anonymous place holders
              placeholder_key = match[2].intern
              @params[placeholder_key] = "#{match[1]}"
              @placeholders[placeholder_key] = [
                match_key, Behavior.count_parens_up_to(source, match.offset(1)[0])
              ]
            end
          end
        end
      end

      # ==== Parameters
      # list<Array>:: A list to which the ancestors should be added.
      #
      # ==== Returns
      # Array:: All the ancestor behaviors of this behavior.
      def find_ancestors(list = [])
        if parent.nil?
          list
        else
          list.push parent
          parent.find_ancestors list
          list
        end
      end

      # ==== Returns
      # Fixnum:: Number of regexp captures in the :path condition.
      def path_captures
        return 0 unless conditions[:path]
        Behavior.count_parens_up_to(conditions[:path], conditions[:path].size)
      end

      # ==== Returns
      # Fixnum:: Total number of previous path captures.
      def total_previous_captures
        ancestors.map{|a| a.path_captures}.inject(0){|sum, n| sum + n}
      end

      # def merge_with_ancestors
      #   self.class.new(merged_conditions, merged_params)
      # end

      # ==== Parameters
      # conditions<Hash>::
      #   The conditions to compile. Defaults to merged_conditions.
      #
      # ==== Returns
      # Hash:: The compiled conditions, with each value as a Regexp object.
      def compiled_conditions(conditions = merged_conditions)
        conditions.inject({}) do |compiled,(k,v)|
          compiled.merge k => Regexp.new(v)
        end
      end

      # ==== Parameters
      # params<Hash>:: The params to compile. Defaults to merged_params.
      # placeholders<Hash>::
      #   The route placeholders for this behavior. Defaults to
      #   merged_placeholders.
      #
      # ==== Returns
      # String:: The params hash in an eval'able form.
      #
      # ==== Examples
      #   compiled_params({ :controller => "admin/:controller" })
      #     # => { :controller => "'admin/' + matches[:path][1]" }
      #
      def compiled_params(params = merged_params, placeholders = merged_placeholders)
        compiled = {}
        params.each_pair do |key, value|
          unless value.is_a? String
            raise ArgumentError, "param value for #{key.to_s} must be string (#{value.inspect})"
          end
          result = []
          value = value.dup
          match = true
          while match
            if match = SEGMENT_REGEXP_WITH_BRACKETS.match(value)
              result << match.pre_match unless match.pre_match.empty?
              ph_key = match[1][1..-1].intern
              if match[2] # has brackets, e.g. :path[2]
                result << :"#{ph_key}#{match[3]}"
              else # no brackets, e.g. a named placeholder such as :controller
                if place = placeholders[ph_key]
                  result << :"#{place[0]}#{place[1]}"
                else
                  raise "Placeholder not found while compiling routes: :#{ph_key}"
                end
              end
              value = match.post_match
            elsif match = JUST_BRACKETS.match(value)
              # This is a reference to :path
              result << match.pre_match unless match.pre_match.empty?
              result << :"path#{match[1]}"
              value = match.post_match
            else
              result << value unless value.empty?
            end
          end
          compiled[key] = Behavior.array_to_code(result).gsub("\\_", "_")
        end
        compiled
      end
    end # Behavior
  end
end
