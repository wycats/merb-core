require File.join(File.dirname(__FILE__), "spec_helper")

describe "Deferred routes" do

  before :each do
    Merb::Router.prepare do |r|      
      r.match("/deferred/:zoo").defer_to do |request, params|
        params.merge(:controller => "w00t") if params[:zoo]
      end
      r.default_routes
    end    
  end
  
  it "should match routes based on the incoming params" do
    route_to("/deferred/baz", :boo => "12").should have_route(:controller => "w00t", :zoo => "baz")
  end

  it "should fall back to the default route if the deferred condition is not met" do
    route_to("/deferred").should have_route(:controller => "deferred", :action => "index")    
  end
  
end