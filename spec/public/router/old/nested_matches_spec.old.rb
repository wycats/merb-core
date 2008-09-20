require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "A route derived from the blocks of #match" do
  
  # The following match specs fail because the :controller and :action params
  # must be specified in #to instead of #match. #match is now reserved for
  # conditions on named segments and Request methods.
  # == Example:
  # Old:    r.match("/foo", :controller => "foos", :action => "index").to
  # New:    r.match("/foo").to(:controller => "foos", :action => "index")

  it "should inherit the :controller option." do
    Merb::Router.prepare do |r|
      r.match('/alpha', :controller=>'Alphas') do |alpha|
        alpha.match('').to(:action=>'normal')
      end
    end
    route_to('/alpha').should have_route(:controller=>'Alphas',:action=>'normal')
  end

  it "should inherit the :action option." do
    Merb::Router.prepare do |r|
      r.match('/alpha', :action=>'wierd') do |alpha|
        alpha.match('').to(:controller=>'Alphas')
      end
    end
    route_to('/alpha').should have_route(:controller=>'Alphas',:action=>'wierd')
  end

  it "should inherit the default :action of 'index'" do
    Merb::Router.prepare do |r|
      r.match('/alpha', :controller=>'Alphas') do |alpha|
        alpha.match('').to({})
      end
    end
    route_to('/alpha').should have_route(:controller=>'Alphas',:action=>'index')
  end

  it "should make use of the :params option" do
    Merb::Router.prepare do |r|
      r.match('/alpha', :controller=>'Alphas', :params =>{:key=>'value'}) do |alpha|
        alpha.match('').to(:action=>'normal',:key2=>'value2')
      end
    end
    route_to('/alpha').should have_route(:controller=>'Alphas',:key=>'value',:action=>'normal',:key2=>'value2')
  end

  it "should inherit the parameters through many levels" do
    Merb::Router.prepare do |r|
      r.match('/alpha', :controller=>'Alphas') do |alpha|
        alpha.match('/beta', :action=>'normal') do |beta|
          beta.match('/:id').to(:id=>':id')
        end
      end
    end
    route_to('/alpha/beta/gamma').should have_route(:controller=>'Alphas',:action=>'normal', :id=>'gamma')
  end
end
