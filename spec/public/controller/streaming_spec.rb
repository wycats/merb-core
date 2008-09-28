require File.join(File.dirname(__FILE__), "spec_helper")

Controllers = Merb::Test::Fixtures::Controllers

describe Merb::Controller, "#nginx_send_file" do
  
  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")    
    Merb::Router.prepare do |r|
      r.default_routes
    end

    @controller = dispatch_to(Merb::Test::Fixtures::Controllers::Streaming, :x_accel_redirect)
  end
  
  it "returns a space" do
    @controller.body.should == " "
  end

  it 'sets X-Accel-Redirect header using first argument value' do
    @controller.headers['X-Accel-Redirect'].should == "/protected/content.pdf"
  end

  describe "when given second argument" do
    it 'sets Content-Type header using second argument value' do
      @controller.headers['Content-Type'].should == "application/pdf"
    end
  end


  describe "when given only first argument" do
    before(:each) do
      @controller = dispatch_to(Merb::Test::Fixtures::Controllers::Streaming, :x_accel_redirect_with_default_content_type)
    end
    
    it 'sets Content-Type header to empty string and sets Nginx determine it' do
      @controller.headers['Content-Type'].should == ""
    end
  end
end
