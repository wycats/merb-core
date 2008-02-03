require 'rubygems'
require 'merb-core'
Merb.push_path(:view, File.dirname(__FILE__) / "views")
Merb::Router.prepare do |r|
  r.default_routes
end

require 'application'

Merb.start :environment => 'development',
           :adapter     => 'thin',
           :framework => {}