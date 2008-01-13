module Merb::RenderMixin
  
  # ==== Parameters
  # base<Module>:: Module that is including RenderMixin (probably a controller)
  def self.included(base)
    base.class_eval do
      class_inheritable_accessor :_layout, :_cached_templates
      attr_accessor :template
    end
  end
  
  def render(thing = nil, opts = {})
    opts, thing = thing, nil if thing.is_a?(Hash)
    thing ||= params[:action]
    
    case thing
    when Symbol
      
    when String
      
    end
  end
  
end