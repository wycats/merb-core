module Merb
  module Test
    module ViewHelper
      
      # small utility class for working with
      # the Hpricot parser class
      class DocumentOutput
        def initialize(response_body)
          @parser = Hpricot.parse(response_body)
        end

        def content_for(css_query)
          match = @parser.search(css_query).first
          match.inner_text unless match.nil?
        end

        def content_for_all(css_query)
          matches = @parser.search(css_query).collect{|ele| ele.inner_text}
        end

        def [](css_query)
          @parser.search(css_query)
        end
      end
      
      # returns the inner content of
      # the first tag found by the css query
      def tag(css_query, output = process_output)
        output.content_for(css_query)
      end
  
      # returns an array of tag contents
      # for all of the tags found by the
      # css query
      def tags(css_query, output = process_output)
        output.content_for_all(css_query)
      end
  
      # returns a raw Hpricot::Elem object
      # for the first result found by the query
      def element(css_query, output = process_output)
        output[css_query].first
      end
  
      # returns an array of Hpricot::Elem objects
      # for the results found by the query
      def elements(css_query, output = process_output)
        Hpricot::Elements[*css_query.to_s.split(",").map{|s| s.strip}.map do |query|
          output[query]
        end.flatten]
      end
  
      def get_elements(css_query, text, output = nil)
        els = elements(*[css_query, output].compact)
        case text
          when String then els.reject {|t| !t.contains?(text) }
          when Regexp then els.reject {|t| !t.matches?(text) }
          else []
        end
      end
  
      protected
        # creates a new DocumentOutput object from the response
        # body if hasn't already been created. This is
        # called automatically by the element and tag methods
        def process_output
          return @output unless @output.nil?
          return @output = DocumentOutput.new(@response_output) unless @response_output.nil?
          
          raise "The response output was not in it's usual places, please provide the output" if @controller.nil? || @controller.body.empty?
          @response_output = @controller.body
          @output = DocumentOutput.new(@controller.body)
        end
    end
  end
end