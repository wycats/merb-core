require 'merb-core/controller/mixins/responder'
module Merb

  class Router
    # Route instances incapsulate information about particular route
    # definition. Route definition ties
    # number of conditions (URL match, HTTP request method) with
    # resulting hash of route parameters:
    # controller, action, format and named parameters
    # from the URL.
    #
    # The following routes definition:
    #
    # Merb::Router.prepare do |r|
    #   r.match("api/:action/:token.:format").to(:controller => "dev").fixatable
    # end
    #
    # maps URL matching pattern to controller named "dev"
    # and specifies fixation for that route. Path and request method are
    # route conditions, controller name, action name, format and
    # value of segment we decided to call :token are route parameters.
    #
    # ==== How route definitions are used.
    #
    # When routes are compiled, each route produces
    # a string with eval-able if/elsif condition statement.
    # This statement together with others constructs body
    # of Merb::Router.match method.
    # Condition statements are Ruby code in form of string.
    #
    # ==== Segments.
    #
    # Route definitions use conventional syntax for named parameters.
    # This splits route path into segments. Static (not changing) segments
    # represented internally as strings, named parameters are stored
    # as symbols and called symbol segments. Symbol segments
    # map to groups in regular expression in resulting condition statement.
    #
    # ==== Route conditions.
    #
    # Because route conditions include path matching,
    # regular expression is created from string that uses
    # :segment format to fetch groups and assign them to
    # named parameters. This regular expression is used
    # to produce compiled statement mentioned above.
    #
    # Route conditions may also include
    # user agent. Symbol segments
    #
    # Here is example of Route conditions:
    # {
    #   :path => /^\/continents\/?(\.([^\/.,;?]+))?$/,
    #   :method => /^get$/
    # }
    #
    #
    # ==== Route parameters.
    #
    # Route parameters is a Hash with controller name,
    # action name and parameters key/value pairs.
    # It is then merged with request.params hash.
    #
    # Example of route parameters:
    #
    # {
    #   :action => "\"index\"",
    #   :format => "path2",
    #   :controller => "\"continents\""
    # }
    #
    # Router takes first matching route and uses it's parameters
    # to dispatch request to certain controller and action.
    #
    # ==== Behavior
    #
    # Each route has utility collaborator called behavior
    # that incapsulates additional information about route
    # (like namespace or if route is deferred) and also
    # provides utility methods.
    #
    # ==== Route registration.
    #
    # When route is added to set of routes, it is called route
    # registration. Registred route knows it's index in routes set.
    #
    # ==== Fixation
    # Fixatable routes allow setting of session key from GET params
    # found in incoming request. This is very useful to allow certain
    # URLs to be used by rich media applications and other kinds
    # of clients that have no other way of passing session identifier.
    #
    # ==== Conditional block.
    # Conditional block is anonymous function that is evaluated
    # when deferred routes are processed. Unless route is deferred,
    # it has no condition block.
    class Route
      attr_reader :conditions, :conditional_block
      attr_reader :params, :behavior, :segments, :index, :symbol

      # ==== Parameters
      # conditions<Hash>:: Conditions for the route.
      # params<Hash>:: Parameters for the route.
      # behavior<Merb::Router::Behavior>::
      #   The associated behavior. Defaults to nil.
      # &conditional_block::
      #   A block with the conditions to be met for the route to take effect.
      def initialize(conditions, params, behavior = nil, &conditional_block)
        @conditions, @params, @behavior = conditions, params, behavior
        @conditional_block = conditional_block
        @fixation=false
        if @behavior && (path = @behavior.merged_original_conditions[:path])
          @segments = segments_from_path(path)
        end
      end

      # ==== Returns
      # Boolean::
      #   Does the router specify a redirect?
      def redirects?
        behavior.redirects?
      end
      
      # ==== Returns
      # Integer::
      #   The status code to use if the route redirects
      def redirect_status
        behavior.redirect_status
      end
      
      # ==== Returns
      # String::
      #   The URL to redirect to if the route redirects
      def redirect_url
        behavior.redirect_url
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

      # Concatenates all route segments and returns result.
      # Symbol segments have colon preserved.
      #
      # ==== Returns
      # String:: The route as a string, e.g. "admin/:controller/:id".
      def to_s
        (segments || []).inject('') do |str,seg|
          str << (seg.is_a?(Symbol) ? ":#{seg}" : seg)
        end
      end

      # Registers the route in the Router.routes array.
      # After registration route has index.
      def register
        @index = Router.routes.size
        Router.routes << self
        self
      end

      # ==== Returns
      # Array:: All the symbols in the segments array.
      def symbol_segments
        (segments || []).select{ |s| s.is_a?(Symbol) }
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

      # Names this route in Router. Name must be a Symbol.
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
      #   behavior's ancestors is a regexp.
      def regexp?
        @regexp ||= behavior.regexp? || behavior.ancestors.any? { |a| a.regexp? }
      end

      # Generates URL using route segments and given parameters.
      # If parameter value responds to :to_param, it is called.
      #
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
                if segment.to_s =~ /_id/ && params[:id].respond_to?(segment)
                  params[segment] = params[:id].send(segment)
                end
                query_params.delete segment
                params[segment] || fallback[segment]
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
          (value.respond_to?(:to_param) ? value.to_param : value).to_s.unescape_regexp
        end.join
        if query_params && format = query_params.delete(:format)
          format = fallback[:format] if format == :current
          url += ".#{format}"
        end
        if query_params
          fragment = query_params.delete(:fragment)
        end
        if query_params && !query_params.empty?
          url += "?" + Merb::Request.params_to_query_string(query_params)
        end
        if fragment
          url += "##{fragment}"
        end
        url
      end

      # Generates and returns if statement used to
      # construct final condition statement of the route.
      #
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

      # Compiles the route to a form used by Merb::Router. This form sometimes
      # referred as condition statement of the route.
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
