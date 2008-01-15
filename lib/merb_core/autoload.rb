module Merb
  autoload :AbstractController,   "merb_core/controller/abstract_controller"
  autoload :BootLoader,           "merb_core/boot/bootloader"
  autoload :Config,               "merb_core/config"
  autoload :Const,                "merb_core/constants"
  autoload :Controller,           "merb_core/controller/merb_controller"
  autoload :ControllerExceptions, "merb_core/controller/exceptions"
  autoload :Dispatcher,           "merb_core/dispatch/dispatcher"
  autoload :ErubisCaptureMixin,   "merb_core/controller/mixins/erubis_capture"
  autoload :Hook,                 "merb_core/hook"
  autoload :Plugins,              "merb_core/plugins"
  autoload :Rack,                 "merb_core/rack"
  autoload :RenderMixin,          "merb_core/controller/mixins/render"
  autoload :Request,              "merb_core/dispatch/request"
  autoload :ResponderMixin,       "merb_core/controller/mixins/responder"
  autoload :Router,               "merb_core/dispatch/router"
  autoload :SessionMixin,         "merb_core/dispatch/session"
end

# Require this rather than autoloading it so we can be sure the default templater
# gets registered
require "merb_core/controller/template"
require "merb_core/hook"

module Merb
  module InlineTemplates; end
end