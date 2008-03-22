require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::Controller, " responds" do
  
  before do
    Merb.push_path(:layout, File.dirname(__FILE__) / "controllers" / "views" / "layouts")    
    Merb::Router.prepare do |r|
      r.default_routes
    end
  end
  
  it "should default the mime-type to HTML" do
    dispatch_to(Merb::Test::Fixtures::Controllers::HtmlDefault, :index).body.should == "HTML: Default"
  end

  it "should use other mime-types if they are provided on the class level" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::ClassProvides, :index, {}, :http_accept => "application/xml")
    controller.body.should == "<XML:Class provides='true' />"
  end

  it "should fail if none of the acceptable mime-types are available" do
    calling { dispatch_to(Merb::Test::Fixtures::Controllers::ClassProvides, :index, {}, :http_accept => "application/json") }.
      should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end

  it "should use mime-types that are provided at the local level" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::LocalProvides, :index, {}, :http_accept => "application/xml")
    controller.body.should == "<XML:Local provides='true' />"
  end

  it "should use the first mime-type when accepting anything */*" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::MultiProvides, :index, {}, :http_accept => "*/*")
    controller.body.should == "HTML: Multi"
  end

  it "should use the first mime-type when accepting anything */*, even if something unprovidable comes first" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::HtmlDefault, :index, {}, :http_accept => "application/json, */*")
    controller.body.should == "HTML: Default"
  end

  it "should use the pick the first mime-type from the list not the */*" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::MultiProvides, :index, {}, :http_accept => "text/javascript, */*")
    controller.body.should == "JS: Multi"
  end
  
  it "should pick the first mime-type if no specific supported content-type matches are *available*" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::MultiProvides, :index, {}, :http_accept => "image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, */*")
    controller.body.should == "HTML: Multi"
  end

  it "should pick the first mime-type if no specific supported content-type matches are actually *provided*" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::MultiProvides, :index, {}, :http_accept => "application/json, */*")
    controller.body.should == "HTML: Multi"
  end
  
  it "should select the format based on params supplied to it with class provides" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::ClassProvides, :index, :format => "xml")
    controller.content_type.should == :xml    
  end
  
  it "should select the format based on params supplied to it with instance provides" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::LocalProvides, :index, :format => "xml")
    controller.content_type.should == :xml    
  end
  
  it "should properly add formats when only_provides is called in action" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::OnlyProvides, :index, {}, :http_accept => "application/xml")
    controller.content_type.should == :xml
  end

  it "should properly remove formats when only_provides is called in action" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::OnlyProvides, :index, {}, :http_accept => "application/html")
    lambda { controller.content_type }.should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end

  it "should properly add formats when only_provides is called in controller" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::ClassOnlyProvides, :index, {}, :http_accept => "application/xml")
    controller.content_type.should == :xml
  end

  it "should properly remove formats when only_provides is called in controller" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::ClassOnlyProvides, :index, {}, :http_accept => "application/html")
    lambda { controller.content_type }.should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end

  it "should properly remove formats when does_not_provide is called in action" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::OnlyProvides, :index, {}, :http_accept => "application/html")
    lambda { controller.content_type }.should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end

  it "should properly remove formats when does_not_provide is called in controller" do
    controller = dispatch_to(Merb::Test::Fixtures::Controllers::ClassOnlyProvides, :index, {}, :http_accept => "application/html")
    lambda { controller.content_type }.should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end
end
