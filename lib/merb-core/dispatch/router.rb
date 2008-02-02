require 'merb-core/dispatch/router/cached_proc'
require 'merb-core/dispatch/router/behavior'
require 'merb-core/dispatch/router/route'

# DOC: Yehuda Katz FAILED
module Merb

  # DOC: Yehuda Katz FAILED
  class Router
    SEGMENT_REGEXP = /(:([a-z_][a-z0-9_]*|:))/
    SEGMENT_REGEXP_WITH_BRACKETS = /(:[a-z_]+)(\[(\d+)\])?/
    JUST_BRACKETS = /\[(\d+)\]/
    PARENTHETICAL_SEGMENT_STRING = "([^\/.,;?]+)".freeze
    
    @@named_routes = {}
    @@routes = []
    cattr_accessor :routes, :named_routes
    
    class << self

      # DOC: Yehuda Katz FAILED
      def append(&block)
        prepare(@@routes, [], &block)
      end

      # DOC: Yehuda Katz FAILED
      def prepend(&block)
        prepare([], @@routes, &block)
      end

      # DOC: Yehuda Katz FAILED
      def prepare(first = [], last = [], &block)
        @@routes = []
        yield Behavior.new({}, { :action => 'index' }) # defaults
        @@routes = first + @@routes + last
        compile
      end

      # DOC: Yehuda Katz FAILED
      def compiled_statement
        @@compiled_statement = "lambda { |request|\n"
        @@compiled_statement << "  params = request.params\n"
        @@compiled_statement << "  cached_path = request.path\n  cached_method = request.method.to_s\n  "
        @@routes.each_with_index { |route, i| @@compiled_statement << route.compile(i == 0) }
        @@compiled_statement << "  else\n    [nil, {}]\n"
        @@compiled_statement << "  end\n"
        @@compiled_statement << "}"
      end

      # DOC
      def compile
        puts "compiled route: #{compiled_statement}" if $DEBUG
        meta_def(:match, &eval(compiled_statement))
      end

      # DOC
      def generate(name, params = {}, fallback = {})
        name = name.to_sym
        unless @@named_routes.key? name
          raise "Named route not found: #{name}"
        else
          @@named_routes[name].generate(params, fallback)
        end
      end
    end # self
    
  end
end