module Merb
  class Router
    
    # The Behavior class is an interim route-building class that ties 
    # pattern-matching +conditions+ to output parameters, +params+.
    class Behavior
      attr_reader :placeholders, :conditions, :params
      attr_accessor :parent
      
      class << self
        # Count the number of open parentheses in +string+, up to and including +pos+
        def count_parens_up_to(string, pos)
          string[0..pos].gsub(/[^\(]/, '').size
        end
        
        # Concatenate strings and remove regexp end caps
        def concat_without_endcaps(string1, string2)
          return nil if !string1 and !string2
          return string1 if string2.nil?
          return string2 if string1.nil?
          s1 = string1[-1] == ?$ ? string1[0..-2] : string1
          s2 = string2[0] == ?^ ? string2[1..-1] : string2
          s1 + s2
        end
        
        # Join an array's elements into a string using " + " as a joiner, and
        # surround string elements in quotes.
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
      
      def initialize(conditions = {}, params = {}, parent = nil)
        # Must wait until after deducing placeholders to set @params !
        @conditions, @params, @parent = conditions, {}, parent
        @placeholders = {}
        stringify_conditions
        copy_original_conditions
        deduce_placeholders
        @params.merge! params
      end
      
      def add(path, params = {})
        match(path).to(params)
      end
      
      # Matches a +path+ and any number of optional request methods as conditions of a route.
      # Alternatively, +path+ can be a hash of conditions, in which case +conditions+ is ignored.
      # Yields a new instance so that sub-matching may occur.
      def match(path = '', conditions = {}, &block)
        if path.is_a? Hash
          conditions = path
        else
          conditions[:path] = path
        end
        match_without_path(conditions, &block)
      end
      
      def match_without_path(conditions = {})
        new_behavior = self.class.new(conditions, {}, self)
        conditions.delete :path if ['', '^$'].include?(conditions[:path])
        yield new_behavior if block_given?
        new_behavior
      end
      
      def to_route(params = {}, &conditional_block)
        @params.merge! params
        Route.new compiled_conditions, compiled_params, self, &conditional_block
      end
      
      # Creates a Route from one or more Behavior objects, unless a +block+ is passed in.
      # If a block is passed in, a Behavior object is yielded and further .to operations
      # may be called in the block.  For example:
      # 
      #   r.match('/:controller/:id).to(:action => 'show')
      # 
      # vs.
      #   
      #   r.to :controller => 'simple' do |s|
      #     s.match('/test').to(:action => 'index')
      #     s.match('/other').to(:action => 'other')
      #   end
      # 
      def to(params = {}, &block)
        if block_given?
          new_behavior = self.class.new({}, params, self)
          yield new_behavior if block_given?
          new_behavior
        else
          to_route(params).register
        end
      end
      
      # Takes a block and stores it for defered conditional routes. 
      # The block takes the +request+ object and the +params+ hash as parameters 
      # and should return a hash of params.
      # 
      #   r.defer_to do |request, params|
      #     params.merge :controller => 'here', :action => 'there'
      #   end
      # 
      def defer_to(params = {}, &conditional_block)
        Router.routes << (route = to_route(params, &conditional_block))
        route
      end
      
      def default_routes(params = {}, &block)
        match(%r{/:controller(/:action(/:id)?)?(\.:format)?}).to(params, &block)
      end
      
      def namespace(name_or_path, &block)
        yield self.class.new(:namespace => name_or_path.to_s)
      end
      
      def resources(name, options = {})
        namespace = options[:namespace] || merged_params[:namespace] || conditions[:namespace]
        
        match_path = namespace ? "/#{namespace}/#{name}" : "/#{name}"
        
        next_level = match match_path
        
        name_prefix = options.delete :name_prefix
        
        if name_prefix.nil? && !namespace.nil?
          name_prefix = namespace_to_name_prefix namespace
        end
        
        options[:controller] ||= merged_params[:controller] || name.to_s
        
        singular = name.to_s.singularize
        
        route_plural_name   = "#{name_prefix}#{name}"
        route_singular_name = "#{name_prefix}#{singular}"
        
        behaviors = []
        
        if member = options.delete(:member)
          member.each_pair do |action, methods|
            behaviors << Behavior.new(
              { :path => %r{^/:id[/;]#{action}(\.:format)?$}, :method => /^(#{[methods].flatten * '|'})$/ },
              { :action => action.to_s }, next_level
            )
            next_level.match("/:id/#{action}").to_route.name(:"#{action}_#{route_singular_name}")
          end
        end
        
        if collection = options.delete(:collection)
          collection.each_pair do |action, methods|
            behaviors << Behavior.new(
              { :path => %r{^[/;]#{action}(\.:format)?$}, :method => /^(#{[methods].flatten * '|'})$/ },
              { :action => action.to_s }, next_level
            )
            next_level.match("/#{action}").to_route.name(:"#{action}_#{route_plural_name}")
          end
        end
        
        routes = many_behaviors_to(behaviors + next_level.send(:resources_behaviors), options)
        
        # Add names to some routes
        [['', :"#{route_plural_name}"],
         ['/:id', :"#{route_singular_name}"],
         ['/new', :"new_#{route_singular_name}"],
         ['/:id/edit', :"edit_#{route_singular_name}"],
         ['/:action/:id', :"custom_#{route_singular_name}"]
        ].each do |path,name|
          next_level.match(path).to_route.name(name)
        end
        
        yield next_level.match("/:#{singular}_id") if block_given?
        
        routes
      end
      
      def resource(name, options = {})
        namespace  = options[:namespace] || merged_params[:namespace] || conditions[:namespace]        
        match_path = namespace ? "/#{namespace}/#{name}" : "/#{name}"
        next_level = match match_path
        
        options[:controller] ||= merged_params[:controller] || name.to_s
        
        # Do not pass :name_prefix option on to to_resource
        name_prefix = options.delete :name_prefix
        
        if name_prefix.nil? && !namespace.nil?
          name_prefix = namespace_to_name_prefix namespace
        end
        
        routes = next_level.to_resource options
        
        route_name = "#{name_prefix}#{name}"
        
        next_level.match('').to_route.name(:"#{route_name}")
        next_level.match('/new').to_route.name(:"new_#{route_name}")
        next_level.match('/edit').to_route.name(:"edit_#{route_name}")
        
        yield next_level if block_given?
        
        routes
      end
      
      def to_resources(params = {}, &block)
        many_behaviors_to resources_behaviors, params, &block
      end
      
      def to_resource(params = {}, &block)
        many_behaviors_to resource_behaviors, params, &block
      end
      
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
      
      def merged_params
        if parent.nil?
          @params
        else
          parent.merged_params.merge(@params)
        end
      end
      
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
      
      def inspect
        "[captures: #{path_captures.inspect}, conditions: #{@original_conditions.inspect}, params: #{@params.inspect}, placeholders: #{@placeholders.inspect}]"
      end
      
      def regexp?
        @conditions_have_regexp
      end
      
    protected
      def namespace_to_name_prefix(name_or_path)
        name_or_path.to_s.tr('/', '_') + '_'
      end
      
      def resources_behaviors(parent = self)
        [
          Behavior.new({ :path => %r[^/?(\.:format)?$],     :method => :get },    { :action => "index" },   parent),
          Behavior.new({ :path => %r[^/index(\.:format)?$], :method => :get },    { :action => "index" },   parent),
          Behavior.new({ :path => %r[^/new$],               :method => :get },    { :action => "new" },     parent),
          Behavior.new({ :path => %r[^/?(\.:format)?$],     :method => :post },   { :action => "create" },  parent),
          Behavior.new({ :path => %r[^/:id(\.:format)?$],   :method => :get },    { :action => "show" },    parent),
          Behavior.new({ :path => %r[^/:id[;/]edit$],       :method => :get },    { :action => "edit" },    parent),
          Behavior.new({ :path => %r[^/:id(\.:format)?$],   :method => :put },    { :action => "update" },  parent),
          Behavior.new({ :path => %r[^/:id(\.:format)?$],   :method => :delete }, { :action => "destroy" }, parent)
        ]
      end
      
      def resource_behaviors(parent = self)
        [
          Behavior.new({ :path => %r{^[;/]new$},        :method => :get },    { :action => "new" },     parent),
          Behavior.new({ :path => %r{^/?(\.:format)?$}, :method => :post },   { :action => "create" },  parent),
          Behavior.new({ :path => %r{^/?(\.:format)?$}, :method => :get },    { :action => "show" },    parent),
          Behavior.new({ :path => %r{^[;/]edit$},       :method => :get },    { :action => "edit" },    parent),
          Behavior.new({ :path => %r{^/?(\.:format)?$}, :method => :put },    { :action => "update" },  parent),
          Behavior.new({ :path => %r{^/?(\.:format)?$}, :method => :delete }, { :action => "destroy" }, parent)
        ]
      end
      
      # Creates a series of routes from an array of Behavior objects.
      # You can pass in optional +params+, and an optional block that will be
      # passed along to the #to method.
      def many_behaviors_to(behaviors, params = {}, &conditional_block)
        behaviors.map { |b| b.to params, &conditional_block }
      end
      
      # Convert conditions to regular expression string sources for consistency
      def stringify_conditions
        @conditions_have_regexp = false
        @conditions.each_pair do |k,v|
          # TODO: Other Regexp special chars
          
          @conditions[k] = case v
          when String,Symbol
            if k == :namespace
              v.to_s
            else
              "^#{v.to_s.escape_regexp}$"
            end
          when Regexp
            @conditions_have_regexp = true
            v.source
          end
        end
      end
      
      def copy_original_conditions
        @original_conditions = {}
        @conditions.each_pair do |key, value|
          @original_conditions[key] = value.dup
        end
        @original_conditions
      end
      
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
      
      def ancestors(list = [])
        if parent.nil?
          list
        else
          list.push parent
          parent.ancestors list
          list
        end
      end
      
      # Count the number of regexp captures in the :path condition
      def path_captures
        return 0 unless conditions[:path]
        Behavior.count_parens_up_to(conditions[:path], conditions[:path].size)
      end
      
      def total_previous_captures
        ancestors.map{|a| a.path_captures}.inject(0){|sum, n| sum + n}
      end
      
      # def merge_with_ancestors
      #   self.class.new(merged_conditions, merged_params)
      # end
      
      def compiled_conditions(conditions = merged_conditions)
        conditions.inject({}) do |compiled,(k,v)|
          compiled.merge k => Regexp.new(v)
        end
      end
      
      # Compiles the params hash into 'eval'-able form.
      # 
      #   @params = {:controller => "admin/:controller"}
      # 
      # Could become:
      # 
      #   { :controller => "'admin/' + matches[:path][1]" }
      #
      def compiled_params(params = merged_params, placeholders = merged_placeholders)
        compiled = {}
        params.each_pair do |key, value|
          unless value.is_a? String
            raise ArgumentError, "param value must be string (#{value.inspect})"
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