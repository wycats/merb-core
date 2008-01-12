require 'enumerator'

module Merb
  class << self
    
    def available_mime_types
      ResponderMixin::Rest::TYPES
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
    def add_mime_type(key,transform_method, values,new_response_headers = {})
      raise ArgumentError unless key.is_a?(Symbol) && values.is_a?(Array)
      ResponderMixin::TYPES.update(key => 
        {:types => values, :transform_method => transform_method})
      add_response_headers!(key, new_response_headers)
    end
    
    # Removes a MIME-type from the mime-type list
    #
    # ==== Parameters
    # key<Symbol>:: The key that represents the mime-type to remove
    def remove_mime_type(key)
      # :all is the key for */*; it can't be removed
      return false if key == :all
      ResponderMixin::TYPES.delete(key)
      remove_response_headers!(key)      
    end
    
    def mime_transform_method(key)
      raise ArgumentError, ":#{key} is not a valid MIME-type" unless ResponderMixin::TYPES.has?(key)
      ResponderMixin::TYPES[key][:transform_method]
    end
    
    
    
  end
end