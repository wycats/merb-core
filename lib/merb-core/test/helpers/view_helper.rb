module Merb
  module Test
    module ViewHelper

      # Small utility class for working with the Hpricot parser class
      class DocumentOutput

        # ==== Parameters
        # response_body<String>:: The response body to parse with Hpricot.
        def initialize(response_body)
          @parser = Hpricot.parse(response_body)
        end

        # ==== Parameters
        # css_query<String>::
        #   A CSS query to find the element for, e.g. "ul.links".
        #
        # ==== Returns
        # String:: The content of the first tag matching the query.
        def content_for(css_query)
          match = @parser.search(css_query).first
          match.inner_text unless match.nil?
        end

        # ==== Parameters
        # css_query<String>:: A CSS query to find the elements for.
        #
        # ==== Returns
        # Array[String]:: Content of all tags matching the query.
        def content_for_all(css_query)
          matches = @parser.search(css_query).collect{|ele| ele.inner_text}
        end

        # ==== Parameters
        # css_query<String>:: A CSS query to find the elements for.
        #
        # ==== Returns
        # Hpricot::Elements:: All tags matching the query.
        def [](css_query)
          @parser.search(css_query)
        end
      end

      # ==== Parameters
      # css_query<String>:: A CSS query to find the element for.
      # output<DocumentOutput>::
      #   The output to look for the element in. Defaults to process_output. 
      #
      # ==== Returns
      # String:: The content of the first tag matching the query.
      def tag(css_query, output = process_output)
        output.content_for(css_query)
      end

      # ==== Parameters
      # css_query<String>:: A CSS query to find the elements for.
      # output<DocumentOutput>::
      #   The output to look for the element in. Defaults to process_output. 
      #
      # ==== Returns
      # Array[String]:: Content of all tags matching the query.
      def tags(css_query, output = process_output)
        output.content_for_all(css_query)
      end

      # ==== Parameters
      # css_query<String>:: A CSS query to find the element for.
      # output<DocumentOutput>::
      #   The output to look for the element in. Defaults to process_output. 
      #
      # ==== Returns
      # Hpricot::Elem:: The first tag matching the query.
      def element(css_query, output = process_output)
        output[css_query].first
      end
  
      # ==== Parameters
      # css_query<String>:: A CSS query to find the elements for.
      # output<DocumentOutput>::
      #   The output to look for the elements in. Defaults to process_output. 
      #
      # ==== Returns
      # Array[Hpricot::Elem]:: All tags matching the query.
      def elements(css_query, output = process_output)
        Hpricot::Elements[*css_query.to_s.split(",").map{|s| s.strip}.map do |query|
          output[query]
        end.flatten]
      end

      # ==== Parameters
      # css_query<String>:: A CSS query to find the elements for.
      # text<String, Regexp>:: A pattern to match tag contents for.
      # output<DocumentOutput>::
      #   The output to look for the elements in. Defaults to process_output. 
      #
      # ==== Returns
      # Array[Hpricot::Elem]:: All tags matching the query and pattern.
      def get_elements(css_query, text, output = nil)
        els = elements(*[css_query, output].compact)
        case text
          when String then els.reject {|t| !t.contains?(text) }
          when Regexp then els.reject {|t| !t.matches?(text) }
          else []
        end
      end
  
      protected

        # ==== Returns
        # DocumentOutput:: Document output from the response body.
        def process_output
          return @output unless @output.nil?
          return @output = DocumentOutput.new(@response_output) unless @response_output.nil?
          
          raise "The response output was not in its usual places, please provide the output" if @controller.nil? || @controller.body.empty?
          @response_output = @controller.body
          @output = DocumentOutput.new(@controller.body)
        end
    end
  end
end