require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
Dir[File.join(File.dirname(__FILE__), "controllers/**/*.rb")].each do |f|
  require f
end

describe "dispatch_to helper helper" do
  
  before(:all) do
    @controller_klass = Merb::Test::DispatchController
  end
  
  it "should dispatch to the given controller and action" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:index)
    
    dispatch_to(@controller_klass, :index)    
  end
  
  it "should dispatch to the given controller and action with params" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:show)
    
    controller = dispatch_to(@controller_klass, :show, :name => "Fred")
    controller.params[:name].should == "Fred"
  end
  
  it "should not hit the router to match it's route" do
    Merb::Router.should_not_receive(:match)
    dispatch_to(@controller_klass, :index)
  end
end

describe  "dispatch_multipart_to helper" do
  
  before(:all) do 
    @controller_klass = Merb::Test::DispatchController
  end
  
  it "should dispatch to the given controller and action" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:index)
    
    dispatch_multipart_to(@controller_klass, :index)    
  end
  
  it "should dispatch to the given controller and action with params" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:show)
    
    controller = dispatch_multipart_to(@controller_klass, :show, :name => "Fred")
    controller.params[:name].should == "Fred"
  end
  
  it "should handle a file object when used as a param" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:show)
    file_name = File.join(File.dirname(__FILE__), "multipart_upload_text_file.txt")
    File.open( file_name ) do |file|
      controller = dispatch_multipart_to(@controller_klass, :show, :my_file => file)
      file_params = controller.params[:my_file]
      file_params[:content_type].should == "text/plain"
      file_params[:size].should == File.size(file_name)
      file_params[:tempfile].should be_a_kind_of(File)
      file_params[:filename].should == "multipart_upload_text_file.txt"
    end
  end
end

describe "get specing helper method" do
  before(:each) do 
    Merb::Router.prepare do |r| 
      r.resources :spec_helper_controller
      r.match("/:controller/:action/:custom").to(:controller => ":controller") 
    end
  end
  
  it "should perform the index action when used with a get" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:index)
    get("/spec_helper_controller")  
  end
  
  it "should perform the index action and have params available" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:index)
    controller = get("/spec_helper_controller", :name => "Harry")
    controller.params[:name].should == "Harry"    
  end
  
  it "should evaluate in the context of the controller in the block" do
    get("/spec_helper_controller") do
      self.class.should == SpecHelperController
    end    
  end
  
  it "should allow for custom router params" do
    controller = get("/spec_helper_controller/index/my_custom_stuff")
    controller.params[:custom].should == "my_custom_stuff"    
  end   
  
  it "should get the show action" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:show)
    controller = get("/spec_helper_controller/my_id")
    controller.params[:id].should == "my_id"    
  end
end

describe "post specing helper method" do
  before(:each) do
    Merb::Router.prepare do |r|
      r.resources :spec_helper_controller
    end
  end
  
  it "should post to the create action" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:create)
    post("/spec_helper_controller")
  end
  
  it "should post to the create action with params" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:create)
    controller = post("/spec_helper_controller", :name => "Harry")
    controller.params[:name].should == "Harry"
  end
end

describe "put specing helper method" do
  before(:each) do
    Merb::Router.prepare do |r|
      r.resources :spec_helper_controller
    end
  end
  it "should put to the update action" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:update)
    put("/spec_helper_controller/1")
  end
  
  it "should put to the update action with params" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:update)
    controller = put("/spec_helper_controller/my_id", :name => "Harry")
    controller.params[:name].should == "Harry"
    controller.params[:id].should   == "my_id"
  end
end

describe "delete specing helper method" do
  before(:each) do
    Merb::Router.prepare do |r|
      r.resources :spec_helper_controller
    end
  end
  it "should put to the update action" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:destroy)
    delete("/spec_helper_controller/1")
  end
  
  it "should put to the update action with params" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:destroy)
    controller = delete("/spec_helper_controller/my_id", :name => "Harry")
    controller.params[:name].should == "Harry"
    controller.params[:id].should   == "my_id"
  end
end

describe "multipart_post specing helper method" do
  before(:each) do
    Merb::Router.prepare do |r|
      r.resources :spec_helper_controller
    end
  end
  
  it "should post to the create action" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:create)
    multipart_post("/spec_helper_controller")
  end
  
  it "should post to the create action with params" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:create)
    controller = multipart_post("/spec_helper_controller", :name => "Harry")
    controller.params[:name].should == "Harry"
  end
  
  it "should upload a file to the action using multipart" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:create)
    file_name = File.join(File.dirname(__FILE__), "multipart_upload_text_file.txt")
    File.open( file_name ) do |file|
      controller = multipart_post("/spec_helper_controller", :my_file => file)
      file_params = controller.params[:my_file]
      file_params[:content_type].should == "text/plain"
      file_params[:size].should == File.size(file_name)
      file_params[:tempfile].should be_a_kind_of(File)
      file_params[:filename].should == "multipart_upload_text_file.txt"
    end
  end
  
end

describe "multipart_put specing helper method" do
  before(:each) do
    Merb::Router.prepare do |r|
      r.resources :spec_helper_controller
    end
  end
  it "should put to the update action multipart" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:update)
    multipart_put("/spec_helper_controller/1")
  end
  
  it "should put to the update action with multipart params" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:update)
    controller = multipart_put("/spec_helper_controller/my_id", :name => "Harry")
    controller.params[:name].should == "Harry"
    controller.params[:id].should   == "my_id"
  end
  
  it "should upload a file to the action using multipart" do
    Merb::Test::ControllerAssertionMock.should_receive(:called).with(:update)
    file_name = File.join(File.dirname(__FILE__), "multipart_upload_text_file.txt")
    File.open( file_name ) do |file|
      controller = multipart_put("/spec_helper_controller/my_id", :my_file => file)
      controller.params[:id].should == "my_id"
      file_params = controller.params[:my_file]
      file_params[:content_type].should == "text/plain"
      file_params[:size].should == File.size(file_name)
      file_params[:tempfile].should be_a_kind_of(File)
      file_params[:filename].should == "multipart_upload_text_file.txt"
    end
  end
end

  