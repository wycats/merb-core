Merb::Router.prepare do |r|
  r.match('/').to(:controller => 'foo', :action =>'index')
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

Merb::Config.use { |c|
  c[:environment]         = 'production',
  c[:framework]           = {},
  c[:log_level]           = 'debug',
  c[:use_mutex]           = false,
  c[:session_store]       = 'cookie',
  c[:session_secret_key]  = '5b7d26c4d99b922929b7c30ce06be0fd58a71500',
  c[:exception_details]   = true,
  c[:reload_classes]      = true,
  c[:reload_time]         = 0.5
}