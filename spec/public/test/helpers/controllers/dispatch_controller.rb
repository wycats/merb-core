class Merb::Test::DispatchController < Merb::Controller
  
  def index
    Merb::Test::ControllerAssertionMock.called(:index)
  end
  
  def show
    Merb::Test::ControllerAssertionMock.called(:show)
  end
  
end