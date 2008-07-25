module Merb::Test::Fixtures::Controllers
  class SomeModel
    def to_xml; "<XML:Model />" end
    def to_json(options = {})
      includes = options[:include].join(', ') rescue ""
      excludes = options[:except].first rescue ""
      "{ 'include': '#{includes}', 'exclude': '#{excludes}' }"
    end
    def to_param
      "1"
    end
  end


  class Testing < Merb::Controller
    self._template_root = File.dirname(__FILE__) / "views"
  end


  class Display < Testing
    def index
      @obj = SomeModel.new
      display @obj
    end    
  end

  class DisplayWithLayout < Testing
    provides :json
    
    def index
      @obj = SomeModel.new
      display @obj, :layout => :custom_arg
    end    
  end

  class DisplayHtmlDefault < Display; end

  class DisplayClassProvides < Display
    provides :xml
  end


  class DisplayLocalProvides < Display
    def index
      @obj = SomeModel.new
      provides :xml
      display @obj
    end
  end


  class DisplayWithTemplate < Display
    layout :custom

    def no_layout
      render :layout => false
    end
    
    def absolute_without_mime
      render :template => File.expand_path(self._template_root) / "merb/test/fixtures/controllers/html_default/index"
    end
    
    def absolute_with_mime
      render :template => File.expand_path(self._template_root) / "merb/test/fixtures/controllers/html_default/index.html"
    end
    
    def relative_without_mime
      render :template => "merb/test/fixtures/controllers/html_default/index"
    end
    
    def relative_with_mime
      render :template => "merb/test/fixtures/controllers/html_default/index.html"
    end
    
  end
  
  class DisplayWithTemplateArgument < Display
    def index
      @obj = SomeModel.new
      display @obj, :layout => :custom_arg
    end

    def index_by_arg
      @obj = SomeModel.new
      display @obj, "merb/test/fixtures/controllers/display_with_template_argument/index.html"
    end
  end

  class DisplayWithStringLocation < Display
    provides :json
    def index
      @obj = SomeModel.new
      display @obj, :location => "/some_resources/#{@obj.to_param}"
    end
  end

  class DisplayWithStatus < Display
    provides :json
    def index
      @obj = SomeModel.new
      display @obj, :status => 500
    end
  end

  class DisplayWithSerializationOptions < Display
    provides :json

    def index
      @obj = SomeModel.new
      display @obj, :include => [:beer, :jazz], :except => [:idiots]
    end

    def index_that_passes_empty_hash
      @obj = SomeModel.new
      display @obj, {}
    end
  end
end
