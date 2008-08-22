class SpecHelperController < Merb::Controller
  
  def index
    Merb::Test::ControllerAssertionMock.called(:index)
  end
  
  def show
    Merb::Test::ControllerAssertionMock.called(:show)
  end
  
  def edit
    Merb::Test::ControllerAssertionMock.called(:edit)
  end
  
  def new
    Merb::Test::ControllerAssertionMock.called(:new)
  end
  
  def create
    Merb::Test::ControllerAssertionMock.called(:create)
  end
  
  def update
    Merb::Test::ControllerAssertionMock.called(:update)
  end
  
  def destroy
    Merb::Test::ControllerAssertionMock.called(:destroy)
  end  
end

module Namespaced
  class SpecHelperController < Merb::Controller
    def index
      Merb::Test::ControllerAssertionMock.called(:index)
    end
  end
end  
        