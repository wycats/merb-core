module Merb

  class Router
    # This entire class is private and should never be accessed outside of
    # Merb::Router and Behavior
    class Route #:nodoc:
      SEGMENT_REGEXP               = /(:([a-z](_?[a-z0-9])*))/
      OPTIONAL_SEGMENT_REGEX       = /^.*?([\(\)])/i
      SEGMENT_REGEXP_WITH_BRACKETS = /(:[a-z_]+)(\[(\d+)\])?/
      JUST_BRACKETS                = /\[(\d+)\]/
      SEGMENT_CHARACTERS           = "[^\/.,;?]".freeze

      attr_reader :conditions, :params, :segments
      attr_reader :index, :variables, :name
      attr_reader :redirect_status, :redirect_url
      attr_accessor :fixation

      def initialize(conditions, params, options = {}, &conditional_block)
        @conditions, @params = conditions, params

        if options[:redirects]
          @redirects         = true
          @redirect_status   = @params[:status]
          @redirect_url      = @params[:url]
          @defaults          = {}
        else
          @defaults          = options[:defaults] || {}
          @conditional_block = conditional_block
        end

        @identifiers       = options[:identifiers]
        @segments          = []
        @symbol_conditions = {}
        @placeholders      = {}
        compile
      end

      def regexp?
        @regexp
      end

      def allow_fixation?
        @fixation
      end

      def redirects?
        @redirects
      end
      
      def to_s
        regexp? ?
          "/#{conditions[:path].source}/" :
          segment_level_to_s(segments)
      end
      
      alias_method :inspect, :to_s

      def register
        @index = Merb::Router.routes.size
        Merb::Router.routes << self
        self
      end
      
      def name=(name)
        @name = name.to_sym
        Router.named_routes[@name] = self
        @name
      end
      
      # === Compiled method ===
      def generate(args = [], defaults = {})
        raise GenerationError, "Cannot generate regexp Routes" if regexp?
        
        params = extract_options_from_args!(args) || { }
        
        # Support for anonymous params
        unless args.empty?
          raise GenerationError, "The route has #{@variables.length} variables: #{@variables.inspect}" if args.length > @variables.length
          
          args.each_with_index do |param, i|
            params[@variables[i]] ||= param
          end
        end
        
        uri = @generator[params, defaults] or raise GenerationError, "Named route #{name} could not be generated with #{params.inspect}"
        uri = Merb::Config[:path_prefix] + uri if Merb::Config[:path_prefix]
        uri
      end

      def compiled_statement(first)
        els_if = first ? '  if ' : '  elsif '

        code = ""
        code << els_if << condition_statements.join(" && ") << "\n"
        if @conditional_block
          code << "    [#{@index.inspect}, block_result]" << "\n"
        else
          code << "    [#{@index.inspect}, #{params_as_string}]" << "\n"
        end
      end

    private
      
    # === Compilation ===

      def compile
        compile_conditions
        compile_params
        @generator = Generator.new(@segments, @symbol_conditions, @identifiers).compiled
      end
      
      # The Generator class handles compiling the route down to a lambda that
      # can generate the URL from a params hash and a default params hash.
      class Generator #:nodoc:
        
        def initialize(segments, symbol_conditions, identifiers)
          @segments          = segments
          @symbol_conditions = symbol_conditions
          @identifiers       = identifiers
          @stack             = []
          @opt_segment_count = 0
          @opt_segment_stack = [[]]
        end
        
        def compiled
          ruby  = ""
          ruby << "lambda do |params, defaults|\n"
          ruby << "  fragment     = params.delete(:fragment)\n"
          ruby << "  query_params = params.dup\n"
          
          with(@segments) do
            ruby << "  include_defaults = true\n"
            ruby << "  return unless url = #{block_for_level}\n"
          end
          
          ruby << "  query_params.delete_if { |key, value| value.nil? }\n"
          ruby << "  unless query_params.empty?\n"
          ruby << '    url << "?#{Merb::Request.params_to_query_string(query_params)}"' << "\n"
          ruby << "  end\n"
          ruby << '  url << "##{fragment}" if fragment' << "\n"
          ruby << "  url\n"
          ruby << "end\n"
          
          eval(ruby)
        end
        
      private
      
        # Cleans up methods a bunch. We don't need to pass the current segment
        # level around everywhere anymore. It's kept track for us in the stack.
        def with(segments, &block)
          @stack.push(segments)
          retval = yield
          @stack.pop
          retval
        end
  
        def segments
          @stack.last || []
        end
        
        def symbol_segments
          segments.flatten.select { |s| s.is_a?(Symbol)  }
        end
        
        def current_segments
          segments.select { |s| s.is_a?(Symbol) }
        end
        
        def nested_segments
          segments.select { |s| s.is_a?(Array) }.flatten.select { |s| s.is_a?(Symbol) }
        end
      
        def block_for_level
          ruby  = ""
          ruby << "if #{segment_level_matches_conditions}\n"
          ruby << "  #{remove_used_segments_in_query_path}\n"
          ruby << "  #{generate_optional_segments}\n"
          ruby << %{ "#{combine_required_and_optional_segments}"\n}
          ruby << "end"
        end
        
        def check_if_defaults_should_be_included
          ruby = ""
          ruby << "include_defaults = "
          symbol_segments.each { |s| ruby << "params[#{s.inspect}] || " }
          ruby << "false"
        end

        # --- Not so pretty ---
        def segment_level_matches_conditions
          conditions = current_segments.map do |segment|
            condition = "(cached_#{segment} = params[#{segment.inspect}] || include_defaults && defaults[#{segment.inspect}])"

            if @symbol_conditions[segment] && @symbol_conditions[segment].is_a?(Regexp)
              condition << " =~ #{@symbol_conditions[segment].inspect}"
            elsif @symbol_conditions[segment]
              condition << " == #{@symbol_conditions[segment].inspect}"
            end

            condition
          end
          
          conditions << "true" if conditions.empty?
          conditions.join(" && ")
        end

        def remove_used_segments_in_query_path
          "#{current_segments.inspect}.each { |s| query_params.delete(s) }"
        end

        def generate_optional_segments
          optionals = []

          segments.each_with_index do |segment, i|
            if segment.is_a?(Array) && segment.any? { |s| !s.is_a?(String) }
              with(segment) do
                @opt_segment_stack.last << (optional_name = "_optional_segments_#{@opt_segment_count += 1}")
                @opt_segment_stack.push []
                optionals << "#{check_if_defaults_should_be_included}\n"
                optionals << "#{optional_name} = #{block_for_level}"
                @opt_segment_stack.pop
              end
            end
          end

          optionals.join("\n")
        end

        def combine_required_and_optional_segments
          bits = ""

          segments.each_with_index do |segment, i|
            bits << case
              when segment.is_a?(String) then segment
              when segment.is_a?(Symbol) then '#{param_for_route(cached_' + segment.to_s + ')}'
              when segment.is_a?(Array) && segment.any? { |s| !s.is_a?(String) } then "\#{#{@opt_segment_stack.last.shift}}"
              else ""
            end
          end

          bits
        end
        
        def param_for_route(param)
          case param
            when String, Symbol, Numeric, TrueClass, FalseClass, NilClass
              param
            else
              _, identifier = @identifiers.find { |klass, _| param.is_a?(klass) }
              identifier ? param.send(identifier) : param
          end
        end
        
      end

    # === Conditions ===

      def compile_conditions
        @original_conditions = conditions.dup

        if path = conditions[:path]
          path = [path].flatten.compact
          if path = compile_path(path)
            conditions[:path] = Regexp.new("^#{path}$")
          else
            conditions.delete(:path)
          end
        end
      end

      # The path is passed in as an array of different parts. We basically have
      # to concat all the parts together, then parse the path and extract the
      # variables. However, if any of the parts are a regular expression, then
      # we abort the parsing and just convert it to a regexp.
      def compile_path(path)
        @segments = []
        compiled  = ""

        return nil if path.nil? || path.empty?

        path.each do |part|
          case part
          when Regexp
            @regexp   = true
            @segments = []
            compiled << part.source.sub(/^\^/, '').sub(/\$$/, '')
          when String
            segments = segments_with_optionals_from_string(part.dup)
            compile_path_segments(compiled, segments)
            # Concat the segments
            unless regexp?
              if @segments[-1].is_a?(String) && segments[0].is_a?(String)
                @segments[-1] << segments.shift
              end
              @segments.concat segments
            end
          else
            raise ArgumentError.new("A route path can only be specified as a String or Regexp")
          end
        end
        
        @variables = @segments.flatten.select { |s| s.is_a?(Symbol)  }

        compiled
      end

      # Simple nested parenthesis parser
      def segments_with_optionals_from_string(path, nest_level = 0)
        segments = []

        # Extract all the segments at this parenthesis level
        while segment = path.slice!(OPTIONAL_SEGMENT_REGEX)
          # Append the segments that we came across so far
          # at this level
          segments.concat segments_from_string(segment[0..-2]) if segment.length > 1
          # If the parenthesis that we came across is an opening
          # then we need to jump to the higher level
          if segment[-1,1] == '('
            segments << segments_with_optionals_from_string(path, nest_level + 1)
          else
            # Throw an error if we can't actually go back down (aka syntax error)
            raise "There are too many closing parentheses" if nest_level == 0
            return segments
          end
        end

        # Save any last bit of the string that didn't match the original regex
        segments.concat segments_from_string(path) unless path.empty?

        # Throw an error if the string should not actually be done (aka syntax error)
        raise "You have too many opening parentheses" unless nest_level == 0

        segments
      end

      def segments_from_string(path)
        segments = []

        while match = (path.match(SEGMENT_REGEXP))
          segments << match.pre_match unless match.pre_match.empty?
          segments << match[2].intern
          path = match.post_match
        end

        segments << path unless path.empty?
        segments
      end

      # --- Yeah, this could probably be refactored
      def compile_path_segments(compiled, segments)
        segments.each do |segment|
          case segment
          when String
            compiled << Regexp.escape(segment)
          when Symbol
            condition = (@symbol_conditions[segment] ||= @conditions.delete(segment))
            compiled << compile_segment_condition(condition)
            # Create a param for the Symbol segment if none already exists
            @params[segment] = "#{segment.inspect}" unless @params.has_key?(segment)
            @placeholders[segment] ||= capturing_parentheses_count(compiled)
          when Array
            compiled << "(?:"
            compile_path_segments(compiled, segment)
            compiled << ")?"
          else
            raise ArgumentError, "conditions[:path] segments can only be a Strings, Symbols, or Arrays"
          end
        end
      end

      # Handles anchors in Regexp conditions
      def compile_segment_condition(condition)
        return "(#{SEGMENT_CHARACTERS}+)" unless condition
        return "(#{condition})"           unless condition.is_a?(Regexp)

        condition = condition.source
        # Handle the start anchor
        condition = if condition =~ /^\^/
          condition[1..-1]
        else
          "#{SEGMENT_CHARACTERS}*#{condition}"
        end
        # Handle the end anchor
        condition = if condition =~ /\$$/
          condition[0..-2]
        else
          "#{condition}#{SEGMENT_CHARACTERS}*"
        end

        "(#{condition})"
      end

      def compile_params
        # Loop through each param and compile it
        @defaults.merge(@params).each do |key, value|
          if value.nil?
            @params.delete(key)
          elsif value.is_a?(String)
            @params[key] = compile_param(value)
          else
            @params[key] = value.inspect
          end
        end
      end

      # This was pretty much a copy / paste from the old router
      def compile_param(value)
        result = []
        match  = true
        while match
          if match = SEGMENT_REGEXP_WITH_BRACKETS.match(value)
            result << match.pre_match.inspect unless match.pre_match.empty?
            placeholder_key = match[1][1..-1].intern
            if match[2] # has brackets, e.g. :path[2]
              result << "#{placeholder_key}#{match[3]}"
            else # no brackets, e.g. a named placeholder such as :controller
              if place = @placeholders[placeholder_key]
                # result << "(path#{place} || )" # <- Defaults
                with_defaults  = ["(path#{place}"]
                with_defaults << " || #{@defaults[placeholder_key].inspect}" if @defaults[placeholder_key]
                with_defaults << ")"
                result << with_defaults.join
              else
                raise GenerationError, "Placeholder not found while compiling routes: #{placeholder_key.inspect}. Add it to the conditions part of the route."
              end
            end
            value = match.post_match
          elsif match = JUST_BRACKETS.match(value)
            result << match.pre_match.inspect unless match.pre_match.empty?
            result << "path#{match[1]}"
            value = match.post_match
          else
            result << value.inspect unless value.empty?
          end
        end

        result.join(' + ').gsub("\\_", "_")
      end

      def condition_statements
        statements = []

        conditions.each_pair do |key, value|
          statements << case value
          when Regexp
            captures = ""

            if (max = capturing_parentheses_count(value)) > 0
              captures << (1..max).to_a.map { |n| "#{key}#{n}" }.join(", ")
              captures << " = "
              captures << (1..max).to_a.map { |n| "$#{n}" }.join(", ")
            end

            # Note: =~ is slightly faster than .match
            %{(#{value.inspect} =~ cached_#{key} #{' && ((' + captures + ') || true)' unless captures.empty?})}
          when Array
            %{(#{arrays_to_regexps(value).inspect} =~ cached_#{key})}
          else
            %{(cached_#{key} == #{value.inspect})}
          end
        end

        if @conditional_block
          statements << "(block_result = #{CachedProc.new(@conditional_block)}.call(request, #{params_as_string}))"
        end

        statements
      end

      def params_as_string
        elements = params.keys.map do |k|
          "#{k.inspect} => #{params[k]}"
        end
        "{#{elements.join(', ')}}"
      end

    # ---------- Utilities ----------
      
      def arrays_to_regexps(condition)
        return condition unless condition.is_a?(Array)
        
        source = condition.map do |value|
          value = if value.is_a?(Regexp)
            value.source
          else
            "^#{Regexp.escape(value.to_s)}$"
          end
          "(?:#{value})"
        end
        
        Regexp.compile(source.join('|'))
      end
    
      def segment_level_to_s(segments)
        (segments || []).inject('') do |str, seg|
          str << case seg
            when String then seg
            when Symbol then ":#{seg}"
            when Array  then "(#{segment_level_to_s(seg)})"
          end
        end
      end

      def capturing_parentheses_count(regexp)
        regexp = regexp.source if regexp.is_a?(Regexp)
        regexp.scan(/(?!\\)[(](?!\?[#=:!>-imx])/).length
      end
    end
  end  
end
