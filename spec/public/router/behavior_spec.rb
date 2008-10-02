require File.join(File.dirname(__FILE__), "spec_helper")

describe Merb::Router::Behavior do
  
  describe "#capture" do
    
    it "should capture the named routes defined in the block" do
      Merb::Router.prepare do
        match("/one").register
        match("/two").name(:two)
        
        # --- self. is to get around a helper method
        captured = self.capture do
          match("/three").register
          match("/four").name(:four)
        end
        
        captured.should == Merb::Router.named_routes.reject { |key, _| key == :two }
      end
    end
    
    it "should retain the same names if there are no name_prefixes set" do
      Merb::Router.prepare do
        captured = self.capture do
          match('/one').name(:one)
          match('/two/three').name(:two_three)
        end
        
        Merb::Router.named_routes[:one].should       == captured[:one]
        Merb::Router.named_routes[:two_three].should == captured[:two_three]
      end
    end
    
    it "should still recognize the routes generated before, inside, and after a capture block" do
      Merb::Router.prepare do
        match("/one").to(:controller => "one")
        self.capture do
          match("/two").to(:controller => "two")
        end
        match("/three").to(:controller => "three")
      end
      
      route_for("/one").should   have_route(:controller => "one")
      route_for("/two").should   have_route(:controller => "two")
      route_for("/three").should have_route(:controller => 'three')
    end
    
    it "should not return anything if nothing was defined inside of the block" do
      captured = {}
      
      Merb::Router.prepare do
        captured = self.capture { }
      end
      
      captured.should be_empty
    end
    
    it "should ignore the namespaces that capture is wrapped around" do
      Merb::Router.prepare do
        namespace :admin do
          captured = self.capture do
            match("/one").to(:controller => "hi").name(:one)
            match("/two/three").to(:controller => "hi").name(:two_three)
          end
          
          captured[:one].should       == Merb::Router.named_routes[:admin_one]
          captured[:two_three].should == Merb::Router.named_routes[:admin_two_three]
        end
      end
    end
    
  end
  
end