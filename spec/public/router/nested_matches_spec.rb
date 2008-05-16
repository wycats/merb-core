require File.join(File.dirname(__FILE__), "spec_helper")

describe "A route derived from the blocks of #match" do

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

  it "allows wrapping of nested routes all having shared argument" do
    Merb::Router.prepare do |r|
      r.match('/:language') do |i18n|
        i18n.match!('/:controller/:action')
      end
    end
    route_to('/fr/hotels/search').should have_route(:controller => 'hotels', :action => "search", :language => "fr")
  end

  it "allows wrapping of nested routes all having shared argument" do
    Merb::Router.prepare do |r|
      r.match(/\/?(.*)?/).to(:language => "[1]") do |l|
        l.match("/guides/:action/:id").to(:controller => "tour_guides")
      end
    end

    route_to('/en/guides/search/london').should have_route(:controller => 'tour_guides', :action => "search", :language => "en", :id => "london")
  end

  it "allows wrapping of nested routes all having shared OPTIONAL argument" do
    Merb::Router.prepare do |r|
      r.match(/\/?(.*)?/).to(:language => "[1]") do |l|
        l.match("/guides/:action/:id").to(:controller => "tour_guides")
      end
    end

    route_to('/guides/search/london').should have_route(:controller => 'tour_guides', :action => "search", :id => "london")
  end

  it "allows wrapping of nested routes all having shared argument with PREDEFINED VALUES" do
    Merb::Router.prepare do |r|
      r.match(/\/?(en|es|fr|be|nl)?/).to(:language => "[1]") do |l|
        l.match("/guides/:action/:id").to(:controller => "tour_guides")
      end
    end

    route_to('/nl/guides/search/denboss').should have_route(:controller => 'tour_guides', :action => "search", :id => "denboss", :language => "nl")
    route_to('/es/guides/search/barcelona').should have_route(:controller => 'tour_guides', :action => "search", :id => "barcelona", :language => "es")
    route_to('/fr/guides/search/lille').should have_route(:controller => 'tour_guides', :action => "search", :id => "lille", :language => "fr")
    route_to('/en/guides/search/london').should have_route(:controller => 'tour_guides', :action => "search", :id => "london", :language => "en")
    route_to('/be/guides/search/brussels').should have_route(:controller => 'tour_guides', :action => "search", :id => "brussels", :language => "be")

    route_to('/guides/search/brussels').should have_route(:controller => 'tour_guides', :action => "search", :id => "brussels")
    route_to('/se/guides/search/stokholm').should have_route(:controller => 'tour_guides', :action => "search", :id => "stokholm", :language => nil)
  end
end
