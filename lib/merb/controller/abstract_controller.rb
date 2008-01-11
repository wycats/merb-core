class Merb::AbstractController
  include Merb::RenderMixin
  include Merb::GeneralControllerMixin
  
  class_inheritable_accessor :_before_filters, :_after_filters
  cattr_accessor :_abstract_subclasses, :_template_path_cache
  self._abstract_subclasses = Set.new
  
  class << self
    def inherited(klass)
      _abstract_subclasses << klass.to_s
      super
    end
  end    
  
  
end