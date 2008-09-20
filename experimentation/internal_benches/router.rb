require File.join(File.dirname(__FILE__), "..", "..", "lib", "merb-core")
require "rubygems"
require "rbench"

Merb::Router.prepare do |r|
  r.namespace :admin do |a|
    a.resources :users do |u|
      u.resources :comments
    end
  end
  
  r.resources :users do |u|
    u.resources :comments
  end
  
  r.match!("/:account/invitation/:token", :account => /^[a-zA-Z]{5,20}$/, :token => /^[\dA-F]{32}$/).name(:conditional)
  
  r.default_routes
end

RBench.run(50_000) do
  column :normal
  column :compiled
  
  report "resources" do
    normal   { Merb::Router.generate( :user, :id => 123) }
    compiled { Merb::Router.generate2(:user, :id => 123) }
  end
  
  report "nested resources" do
    normal   { Merb::Router.generate( :user_comment, :user_id => 123, :id => "456") }
    compiled { Merb::Router.generate2(:user_comment, :user_id => 123, :id => "456") }
  end
  
  report "namespaced nested resource" do
    normal   { Merb::Router.generate( :admin_user_comment, :user_id => 123, :id => "456") }
    compiled { Merb::Router.generate2(:admin_user_comment, :user_id => 123, :id => "456") }
  end
  
  report "route with conditions" do
    normal   { Merb::Router.generate( :conditional, :account => "helloworld", :token => "0987654321ABCDEF0987654321ABCDEF") }
    compiled { Merb::Router.generate2(:conditional, :account => "helloworld", :token => "0987654321ABCDEF0987654321ABCDEF") }
  end
  
  report "default routes" do
    normal   { Merb::Router.generate( :default, :controller => "foo", :action => "bar", :id => 5, :format => :xml) }
    compiled { Merb::Router.generate2(:default, :controller => "foo", :action => "bar", :id => 5, :format => :xml) }
  end
end


__END__

                                    NORMAL | COMPILED |
-------------------------------------------------------
resources                            1.908 |    0.771 |
nested resources                     2.481 |    1.058 |
namespaced nested resource           2.484 |    1.071 |
route with conditions                1.979 |    0.991 |
default routes                       4.059 |    1.244 |