module Merb
  autoload :AbstractController,       "merb-core/controller/abstract_controller"
  autoload :BootLoader,               "merb-core/bootloader"
  autoload :Config,                   "merb-core/config"
  autoload :Const,                    "merb-core/constants"
  autoload :ConditionalGetMixin,      "merb-core/controller/mixins/conditional_get"
  autoload :ControllerMixin,          "merb-core/controller/mixins/controller"
  autoload :ControllerExceptions,     "merb-core/controller/exceptions"
  autoload :Dispatcher,               "merb-core/dispatch/dispatcher"
  autoload :AuthenticationMixin,      "merb-core/controller/mixins/authentication"
  autoload :BasicAuthenticationMixin, "merb-core/controller/mixins/authentication/basic"
  autoload :ErubisCaptureMixin,       "merb-core/controller/mixins/erubis_capture"
  autoload :Plugins,                  "merb-core/plugins"
  autoload :Rack,                     "merb-core/rack"
  autoload :RenderMixin,              "merb-core/controller/mixins/render"
  autoload :Request,                  "merb-core/dispatch/request"
  autoload :ResponderMixin,           "merb-core/controller/mixins/responder"
  autoload :Router,                   "merb-core/dispatch/router"
  autoload :Test,                     "merb-core/test"
  autoload :Worker,                   "merb-core/dispatch/worker"
end

# Require this rather than autoloading it so we can be sure the default template
# gets registered
require 'merb-core/core_ext'
require "merb-core/controller/template"
require "merb-core/controller/merb_controller"

module Merb
  module InlineTemplates; end
end
