class Merb::Controller < AbstractController
  
  class_inheritable_accessor :_session_id_key, :_session_expiry
  cattr_accessor :_subclasses, :_session_secret_key
  self._subclasses = Set.new
  self.session_secret_key = nil
  self._session_id_key = '_session_id'
  self._session_expiry = Time.now + Merb::Const::WEEK * 2
  
  include Merb::ResponderMixin
  include Merb::ControllerExceptions
  
  
end