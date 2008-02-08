require 'rubygems'
require 'merb-core'

Merb::Router.prepare do |r|
  r.default_routes
end

class Foo < Merb::Controller

  ##
  # Returning a string is the easiest.
  
  def index
    "Hello from the index action"
  end

  ##
  # You could also render a string manually through Erubis.
  
  def show
    template_object = Erubis::Eruby.new(<<-EOL)
    <h1>Hello, world</h1>
    <p>Here are the params: <%= params.inspect %></p>
    EOL
    render template_object.result(binding)
  end
  
end

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