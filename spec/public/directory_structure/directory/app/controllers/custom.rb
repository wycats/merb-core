

class Custom < Application

  def string
    "String"
  end

  def template
    render
  end
  
  private
  
  def _template_location(action, type = nil, controller = controller_name)  
    "wonderful/#{action}"
  end
  
end