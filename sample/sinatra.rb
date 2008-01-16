Merb.simple_router

class Application < Merb::Controller

  def index
    "Hello world"
  end
  
  def erb
    provides :xml
    display "<this_is_xml/>", :hello
  end
  
  def erb2
    render "Hello #{params[:name].capitalize || "World"} 2!"
  end
  
end