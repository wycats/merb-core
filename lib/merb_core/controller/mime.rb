module Merb
  class << self

    # An alias for ResponderMixin::TYPES
    def available_mime_types
      ResponderMixin::TYPES
    end

    # Any specific outgoing headers should be included here.  These are not
    # the content-type header but anything in addition to it.
    # +tranform_method+ should be set to a symbol of the method used to
    # transform a resource into this mime type.
    # For example for the :xml mime type an object might be transformed by
    # calling :to_xml, or for the :js mime type, :to_json.
    # If there is no transform method, use nil.
    #
    # ==== Parameters
    # key<Symbol>:: The name of the mime-type. This is used by the provides API
    # transform_method<~to_s?>:: 
    #   The associated method to call on objects to convert them to the
    #   appropriate mime-type. For instance, :json would use :to_json as
    #   its transform_method
    # values<Array[String]>:: 
    #   A list of possible values sent in the Accept header, such as
    #   text/html, that should be associated with this content-type
    def add_mime_type(key, transform_method, values, new_response_headers = {}) 
      enforce!(key => Symbol, values => Array)
      ResponderMixin::TYPES.update(key => 
        {:request_headers   => values, 
         :transform_method  => transform_method,
         :response_headers  => new_response_headers })
    end

    # Removes a MIME-type from the mime-type list
    #
    # ==== Parameters
    # key<Symbol>:: The key that represents the mime-type to remove
    def remove_mime_type(key)
      # :all is the key for */*; it can't be removed
      return false if key == :all
      ResponderMixin::TYPES.delete(key)
    end

    # The method that transforms an object for this mime-type (e.g. :to_json)
    #
    # ==== Parameters
    # key<Symbol>:: The key that represents the mime-type
    def mime_transform_method(key)
      raise ArgumentError, ":#{key} is not a valid MIME-type" unless ResponderMixin::TYPES.has?(key)
      ResponderMixin::TYPES[key][:transform_method]
    end

    # The mime-type for a particular inbound Accepts header
    #
    # ==== Parameters
    # header<String>:: The name of the header you want to find the mime-type for
    def mime_by_request_header(header)
      available_mime_types.find {|key,info| info[request_headers].include?(header)}.first
    end

    # Resets the default mime-types
    # 
    # By default, the mime-types include:
    # :all:: no transform, */*
    # :yaml:: to_yaml, application/x-yaml or text/yaml
    # :text:: to_text, text/plain
    # :html:: to_html, text/html or application/xhtml+xml or application/html
    # :xml:: to_xml, application/xml or text/xml or application/x-xml, adds "Encoding: UTF-8" response header
    # :js:: to_json, text/javascript ot application/javascript or application/x-javascript
    # :json:: to_json, application/json or text/x-json
    def reset_default_mime_types!
      available_mime_types.clear
      Merb.add_mime_type(:all,  nil,      %w[*/*])
      Merb.add_mime_type(:yaml, :to_yaml, %w[application/x-yaml text/yaml])
      Merb.add_mime_type(:text, :to_text, %w[text/plain])
      Merb.add_mime_type(:html, :to_html, %w[text/html application/xhtml+xml application/html])
      Merb.add_mime_type(:xml,  :to_xml,  %w[application/xml text/xml application/x-xml], :Encoding => "UTF-8")
      Merb.add_mime_type(:js,   :to_json, %w[text/javascript application/javascript application/x-javascript])
      Merb.add_mime_type(:json, :to_json, %w[application/json text/x-json])      
    end
    
  end
end