require 'merb-core/controller/mixins/responder'
module Merb
  
  class Router

    class Route
      attr_reader :conditions, :conditional_block
      attr_reader :params, :behavior, :segments, :index, :symbol

      # ==== Parameters
      # conditions<Hash>:: Conditions for the route.
      # params<Hash>:: Parameters for the route.
      # behavior<Merb::Router::Behavior>::
      #   The associated behavior. Defaults to nil.
      # &conditional_block::
      #		A block with the conditions to be met for the route to take effect.
      def initialize(conditions, params, behavior = nil, &conditional_block)
        @conditions, @params, @behavior = conditions, params, behavior
        @conditional_block = conditional_block
        if @behavior && (path = @behavior.merged_original_conditions[:path])
          @segments = segments_from_path(path)
        end
      end

      # ==== Returns
      # Boolean:: True if fixation is allowed.
      def allow_fixation? 
        @fixation
      end 
         
      # ==== Parameters
      # enabled<Boolean>:: True enables fixation on the route.
      def fixatable(enable=true) 
        @fixation = enable 
        self
      end

      # ==== Returns
      # String:: The route as a string, e.g. "admin/:controller/:id".
      def to_s
        segments.inject('') do |str,seg|
          str << (seg.is_a?(Symbol) ? ":#{seg}" : seg)
        end
      end
      
      # Registers the route in the Router.routes array.
      def register
        @index = Router.routes.size
        Router.routes << self
        self
      end
      
      # ==== Returns
      # Array:: All the symbols in the segments array.
      def symbol_segments
        segments.select{ |s| s.is_a?(Symbol) }
      end
      
      # Turn a path into string and symbol segments so it can be reconstructed,
      # as in the case of a named route.
      #
      # ==== Parameters
      # path<String>:: The path to split into segments.
      #
      # ==== Returns
      # Array:: The Symbol and String segments for the path.
      def segments_from_path(path)
        # Remove leading ^ and trailing $ from each segment (left-overs from regexp joining)
        strip = proc { |str| str.gsub(/^\^/, '').gsub(/\$$/, '') }
        segments = []
        while match = (path.match(SEGMENT_REGEXP))
          segments << strip[match.pre_match] unless match.pre_match.empty?
          segments << match[2].intern
          path = strip[match.post_match]
        end
        segments << strip[path] unless path.empty?
        segments
      end
      
      # Names this route in Router.
      #
      # ==== Parameters
      # symbol<Symbol>:: The name of the route.
      #
      # ==== Raises
      # ArgumentError:: symbol is not a Symbol.
      def name(symbol = nil)
        raise ArgumentError unless (@symbol = symbol).is_a?(Symbol)
        Router.named_routes[@symbol] = self
      end

      # ==== Returns
      # Boolean::
      #   True if this route is a regexp, i.e. its behavior or one of the
      #   behaviors ancestors is a regexp.
      def regexp?
        behavior.regexp? || behavior.send(:ancestors).any? { |a| a.regexp? }
      end
      
      # ==== Parameters
      # params<Hash>:: Optional parameters for the route.
      # fallback<Hash>:: Optional parameters for the fallback route.
      #
      # ==== Returns
      # String::
      #   The URL corresponding to the params, using the stored route segments
      #   for reconstruction of the URL.
      def generate(params = {}, fallback = {})
        raise "Cannot generate regexp Routes" if regexp?
        query_params = params.dup if params.is_a? Hash
        url = @segments.map do |segment|
          value =
            if segment.is_a? Symbol
              if params.is_a? Hash
                params[segment] || fallback[segment]
                query_params.delete segment
              else
                if segment == :id && params.respond_to?(:to_param) 
                  params.to_param
                elsif segment == :id && params.is_a?(Fixnum)
                  params
                elsif params.respond_to?(segment)
                  params.send(segment)
                else
                  fallback[segment]
                end
              end
            elsif segment.respond_to? :to_s
              segment
            else
              raise "Segment type '#{segment.class}' can't be converted to a string"
            end
          (value.respond_to?(:to_param) ? value.to_param : value).to_s
        end.join
        if query_params && !query_params.empty?
          url += "?" + Merb::Request.params_to_query_string(query_params)
        end
        url
      end

      # ==== Params
      # params_as_string<String>::
      #   The params hash as a string, e.g. ":foo => 'bar'".
      #
      # ==== Returns
      # Array:: All the conditions as eval'able strings.
      def if_conditions(params_as_string)
        cond = []
        condition_string = proc do |key, value, regexp_string|
          max = Behavior.count_parens_up_to(value.source, value.source.size)
          captures = max == 0 ? "" : (1..max).to_a.map{ |n| "#{key}#{n}" }.join(", ") + " = " +
                                     (1..max).to_a.map{ |n| "$#{n}"}.join(", ")
          " (#{value.inspect} =~ #{regexp_string}) #{" && (" + captures + ")" unless captures.empty?}"
        end
        @conditions.each_pair do |key, value|
          
          # Note: =~ is slightly faster than .match
          cond << case key
          when :path then condition_string[key, value, "cached_path"]
          when :method then condition_string[key, value, "cached_method"]
          else condition_string[key, value, "request.#{key}.to_s"]
          end
        end
        if @conditional_block
          str = "  # #{@conditional_block.inspect.scan(/@([^>]+)/).flatten.first}\n"
          str << "    (block_result = #{CachedProc.new(@conditional_block)}.call(request, params.merge({#{params_as_string}})))" if @conditional_block
          cond << str
        end
        cond
      end

      # Compiles the route to a form used by Merb::Router.
      #
      # ==== Parameters
      # first<Boolean>::
      #   True if this is the first route in set of routes. Defaults to false.
      #
      # ==== Returns
      # String:: The code corresponding to the route in a form suited for eval.
      def compile(first = false)
        code = ""
        default_params = { :action => "index" }
        get_value = proc do |key|
          if default_params.has_key?(key) && params[key][0] != ?"
            "#{params[key]} || \"#{default_params[key]}\""
          else
            "#{params[key]}"
          end
        end
        params_as_string = params.keys.map { |k| "#{k.inspect} => #{get_value[k]}" }.join(', ')
        code << "  els" unless first
        code << "if  # #{@behavior.merged_original_conditions.inspect}  \n"
        code << if_conditions(params_as_string).join(" && ") << "\n"
        code << "    # then\n"
        if @conditional_block
          code << "    [#{@index.inspect}, block_result]\n"
        else
          code << "    [#{@index.inspect}, {#{params_as_string}}]\n"
        end
      end

      # Prints a trace of the behavior for this route.
      def behavior_trace
        if @behavior
          puts @behavior.send(:ancestors).reverse.map{|a| a.inspect}.join("\n"); puts @behavior.inspect; puts
        else
          puts "No behavior to trace #{self}"
        end
      end
    end # Route
  end
end