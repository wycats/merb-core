

class Custom < Application

  def string
    "String"
  end

  def template
    render
  end
  
  private
  
  def _template_location(context, type = nil, controller = controller_name)  
    "wonderful/#{context}"
  end
  
end