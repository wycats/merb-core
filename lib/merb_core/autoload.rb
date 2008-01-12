module Merb
  autoload :AbstractController,   "merb_core/controller/abstract_controller"
  autoload :Const,                "merb_core/constants"
  autoload :Controller,           "merb_core/controller/merb_controller"
  autoload :ControllerExceptions, "merb_core/controller/exceptions"
  autoload :Dispatcher,           "merb_core/dispatch/dispatcher"
  autoload :ErubisCaptureMixin,   "merb_core/controller/mixins/erubis_capture"
  autoload :Plugins,              "merb_core/plugins"
  autoload :RenderMixin,          "merb_core/controller/mixins/render"
  autoload :Request,              "merb_core/dispatch/request"
  autoload :Responder,            "merb_core/controller/mixins/responder"
  autoload :Router,               "merb_core/dispatch/router"
  autoload :SessionMixin,         "merb_core/dispatch/session"
end