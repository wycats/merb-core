module Merb
  module Test
    module Multipart
      require 'rubygems'
      require 'mime/types'

      class Param
        attr_accessor :key, :value

        # ==== Parameters
        # key<~to_s>:: The parameter key.
        # value<~to_s>:: The parameter value.
        def initialize(key, value)
          @key   = key
          @value = value
        end

        # ==== Returns
        # String:: The parameter in a form suitable for a multipart request.
        def to_multipart
          return %(Content-Disposition: form-data; name="#{key}"\r\n\r\n#{value}\r\n)
        end
      end

      class FileParam
        attr_accessor :key, :filename, :content

        # ==== Parameters
        # key<~to_s>:: The parameter key.
        # filename<~to_s>:: Name of the file for this parameter.
        # content<~to_s>:: Content of the file for this parameter.
        def initialize(key, filename, content)
          @key      = key
          @filename = filename
          @content  = content
        end

        # ==== Returns
        # String::
        #   The file parameter in a form suitable for a multipart request.
        def to_multipart
          return %(Content-Disposition: form-data; name="#{key}"; filename="#{filename}"\r\n) + "Content-Type: #{MIME::Types.type_for(@filename)}\r\n\r\n" + content + "\r\n"
        end
      end

      class Post
        BOUNDARY = '----------0xKhTmLbOuNdArY'
        CONTENT_TYPE = "multipart/form-data, boundary=" + BOUNDARY

        # ==== Parameters
        # params<Hash>:: Optional params for the controller.
        def initialize(params = {})
          @multipart_params = []
          push_params(params)
        end

        # Saves the params in an array of multipart params as Param and
        # FileParam objects.
        #
        # ==== Parameters
        # params<Hash>:: The params to add to the multipart params.
        # prefix<~to_s>:: An optional prefix for the request string keys.
        def push_params(params, prefix = nil)
          params.sort_by {|k| k.to_s}.each do |key, value|
            param_key = prefix.nil? ? key : "#{prefix}[#{key}]"
            if value.respond_to?(:read)
              @multipart_params << FileParam.new(param_key, value.path, value.read)
            else
              if value.is_a?(Hash) || value.is_a?(Mash)
                value.keys.each do |k|
                  push_params(value, param_key)
                end
              else
                @multipart_params << Param.new(param_key, value)
              end
            end
          end
        end

        # ==== Returns
        # String, String:: The query and the content type.
        def to_multipart
          query = @multipart_params.collect { |param| "--" + BOUNDARY + "\r\n" + param.to_multipart }.join("") + "--" + BOUNDARY + "--"
          return query, CONTENT_TYPE
        end
      end 

    end    
  end
end