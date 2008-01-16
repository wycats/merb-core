Merb::Router.prepare do |r|
  r.default_routes
end

Merb.push_path(:view, File.dirname(__FILE__) / "views")

class Foo < Merb::Controller
  
  def _template_location(action, type = nil, controller = controller_name)
    "#{action}.#{type}"
  end

  def index
    "Hello"
  end
  
  def foo
    render
  end
  
end
