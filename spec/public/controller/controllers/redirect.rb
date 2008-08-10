module Merb::Test::Fixtures::Controllers
  class Testing < Merb::Controller
    self._template_root = File.dirname(__FILE__) / "views"
  end

  class SimpleRedirect < Testing
    def index
      redirect("/")
    end
  end

  class PermanentRedirect < Testing
    def index
      redirect("/", :permanent => true)
    end
  end

  class RedirectWithMessage < Testing
    def index
      redirect("/", :message => { :notice => "what?" })
    end
  end
  
  class ConsumesMessage < Testing
    def index
      message[:notice].inspect
    end
  end
  
  class SetsMessage < Testing
    def index
      message[:notice] = "Hello"
      message[:notice]
    end
  end
end