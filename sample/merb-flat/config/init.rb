require 'rubygems'
require 'merb-core'
Merb.push_path(:view, Merb.root / "views")
Merb::Router.prepare do |r|
  r.default_routes
end

require 'application'

Merb.start :environment        => 'production',
           :adapter            => 'thin',
           :framework          => {},
           :log_level          => 'debug',
           :use_mutex          => false,
           :session_store      => 'cookie',
           :session_secret_key => '5b7d26c4d99b922929b7c30ce06be0fd58a71500',
           :exception_details  => true,
           :reload_classes     => true,
           :reload_time        => 0.5