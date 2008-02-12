module Merb
  module Test
    module Multipart
      require 'rubygems'
      require 'mime/types'
 
      class Param
        attr_accessor :key, :value
        def initialize(key, value)
          @key   = key
          @value = value
        end
 
        def to_multipart
          return %(Content-Disposition: form-data; name="#{key}"\r\n\r\n#{value}\r\n)
        end
      end
 
      class FileParam
        attr_accessor :key, :filename, :content
        def initialize(key, filename, content)
          @key      = key
          @filename = filename
          @content  = content
        end
 
        def to_multipart
          return %(Content-Disposition: form-data; name="#{key}"; filename="#{filename}"\r\n) + "Content-Type: #{MIME::Types.type_for(@filename)}\r\n\r\n" + content + "\r\n"
        end
      end
 
      class Post
        BOUNDARY = '----------0xKhTmLbOuNdArY'
        CONTENT_TYPE = "multipart/form-data, boundary=" + BOUNDARY
 
        def initialize(params = {})
          @multipart_params = []
          push_params(params)
        end
 
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
 
        def to_multipart
          query = @multipart_params.collect { |param| "--" + BOUNDARY + "\r\n" + param.to_multipart }.join("") + "--" + BOUNDARY + "--"
          return query, CONTENT_TYPE
        end
      end 
 
    end    
  end
end