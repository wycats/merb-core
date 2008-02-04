

class Foo < Merb::Controller

  def _template_location(action, type = nil, controller = controller_name)
    "#{action}.#{type}.erb"
  end

  def index
    "Hello"
  end

  def foo
    render
  end
  
end