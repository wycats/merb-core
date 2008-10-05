require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "When recognizing requests," do
  
  describe "a route with a String path condition" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/info").to(:controller => "info", :action => "foo")
      end
    end
    
    it "should match the path and return the parameters passed to #to" do
      route_for("/info").should have_route(:controller => "info", :action => "foo", :id => nil)
    end
    
    it "should not match a different path" do
      lambda { route_for("/notinfo") }.should raise_not_found
    end
    
    it "should ignore trailing slashes" do
      Merb::Router.prepare do
        match("/hello/").to(:controller => "world")
      end
      
      route_for("/hello").should have_route(:controller => "world")
    end
    
    it "should ignore repeated slashes" do
      Merb::Router.prepare do
        match("/foo///bar").to(:controller => "fubar")
        match("/hello//world").to(:controller => "greetings")
      end
      
      route_for("/foo/bar").should have_route(:controller => "fubar")
      route_for("/hello/world").should have_route(:controller => "greetings")
    end
  end
  
  describe "a route with a Request method condition" do
    
    before(:each) do
      Merb::Router.prepare do
        match(:method => :post).to(:controller => "all", :action => "posting")
      end
    end
    
    it "should match any path with a post method" do
      route_for("/foo/create/12", :method => "post").should have_route(:controller => "all", :action => "posting")
      route_for("", :method => "post").should have_route(:controller => "all", :action => "posting")
    end
    
    it "should not match any paths that don't have a post method" do
      lambda { route_for("/foo/create/12", :method => "get") }.should raise_not_found
      lambda { route_for("", :method => "get") }.should raise_not_found
    end
    
    it "should combine Array elements using OR" do
      Merb::Router.prepare do
        match(:method => [:get, :post]).to(:controller => "hello")
      end
      
      route_for('/anything', :method => "get").should        have_route(:controller => "hello")
      route_for('/anything', :method => "post").should       have_route(:controller => "hello")
      lambda { route_for('/anything', :method => "put")    }.should raise_not_found
      lambda { route_for('/anything', :method => "delete") }.should raise_not_found
    end
    
    it "should be able to handle Regexps inside of condition arrays" do
      Merb::Router.prepare do
        match(:method => [/^g[aeiou]?t$/, :post]).to(:controller => "hello")
      end
      
      route_for('/anything', :method => "get").should        have_route(:controller => "hello")
      route_for('/anything', :method => "post").should       have_route(:controller => "hello")
      lambda { route_for('/anything', :method => "put")    }.should raise_not_found
      lambda { route_for('/anything', :method => "delete") }.should raise_not_found
    end
    
    it "should ignore nil values" do
      Merb::Router.prepare do
        match("/hello", :method => nil).to(:controller => "all")
      end
      
      [:get, :post, :puts, :delete].each do |method|
        route_for("/hello", :method => method).should have_route(:controller => "all")
      end
    end
  end
  
  describe "a route with Request method condition and a path condition" do
    
    before(:each) do
      Merb::Router.prepare do
        match("/foo", :protocol => "http").to(:controller => "plain", :action => "text")
      end
    end
    
    it "should match the route if the path and the protocol match" do
      route_for("/foo", :protocol => "http").should have_route(:controller => "plain", :action => "text")
    end
    
    it "should not match if the route does not match" do
      lambda { route_for("/bar", :protocol => "http") }.should raise_not_found
    end
    
    it "should not match if the protocol does not match" do
      lambda { route_for("/foo", :protocol => "https") }.should raise_not_found
    end
    
    it "should combine Array elements using OR" do
      Merb::Router.prepare do
        match("/hello", :method => [:get, :post]).to(:controller => "hello")
      end
      
      route_for("/hello", :method => "get").should          have_route(:controller => "hello")
      route_for("/hello", :method => "post").should         have_route(:controller => "hello")
      lambda { route_for("/hello",   :method => "put")    }.should raise_not_found
      lambda { route_for("/hello",   :method => "delete") }.should raise_not_found
      lambda { route_for("/goodbye", :method => "get")    }.should raise_not_found
      lambda { route_for("/goodbye", :method => "post")   }.should raise_not_found
      lambda { route_for("/goodbye", :method => "put")    }.should raise_not_found
      lambda { route_for("/goodbye", :method => "delete") }.should raise_not_found
    end
  end
  
  describe "a route containing path variable conditions" do
    
    it "should match only if the condition is satisfied" do
      Merb::Router.prepare do
        match("/foo/:bar", :bar => /\d+/).register
      end
      
      route_for("/foo/123").should have_route(:bar => "123")
      lambda { route_for("/foo/abc") }.should raise_not_found
    end
    
    it "should be able to handle conditions with anchors" do
      Merb::Router.prepare do
        match("/foo/:bar") do
          match(:bar => /^\d+$/).to(:controller => "both")
          match(:bar => /^\d+/ ).to(:controller => "start")
          match(:bar => /\d+$/ ).to(:controller => "end")
          match(:bar => /\d+/  ).to(:controller => "none")
        end
      end
      
      route_for("/foo/123456").should have_route(:controller => "both",  :bar => "123456")
      route_for("/foo/123abc").should have_route(:controller => "start", :bar => "123abc")
      route_for("/foo/abc123").should have_route(:controller => "end",   :bar => "abc123")
      route_for("/foo/ab123c").should have_route(:controller => "none",  :bar => "ab123c")
      lambda { route_for("/foo/abcdef") }.should raise_not_found
    end
    
    it "should match only if all conditions are satisied" do
      Merb::Router.prepare do
        match("/:foo/:bar", :foo => /abc/, :bar => /123/).register
      end
      
      route_for("/abc/123").should   have_route(:foo => "abc",  :bar => "123")
      route_for("/abcd/123").should  have_route(:foo => "abcd", :bar => "123")
      route_for("/abc/1234").should  have_route(:foo => "abc",  :bar => "1234")
      route_for("/abcd/1234").should have_route(:foo => "abcd", :bar => "1234")
      lambda { route_for("/ab/123") }.should raise_not_found
      lambda { route_for("/abc/12") }.should raise_not_found
      lambda { route_for("/ab/12") }.should raise_not_found
    end
    
    it "should allow creating conditions that span default segment dividers" do
      Merb::Router.prepare do
        match("/:controller", :controller => %r[^[a-z]+/[a-z]+$]).register
      end
      
      lambda { route_for("/somewhere") }.should raise_not_found
      route_for("/somewhere/somehow").should have_route(:controller => "somewhere/somehow")
    end
    
    it "should allow creating conditions that match everything" do
      Merb::Router.prepare do
        match("/:glob", :glob => /.*/).register
      end
      
      %w(somewhere somewhere/somehow 123/456/789 i;just/dont-understand).each do |path|
        route_for("/#{path}").should have_route(:glob => path)
      end
    end
    
    it "should allow greedy matches to preceed segments" do
      Merb::Router.prepare do
        match("/foo/:bar/something/:else", :bar => /.*/).register
      end
      
      %w(somewhere somewhere/somehow 123/456/789 i;just/dont-understand).each do |path|
        route_for("/foo/#{path}/something/wonderful").should have_route(:bar => path, :else => "wonderful")
      end
    end
    
    it "should allow creating conditions that proceed a glob" do
      Merb::Router.prepare do
        match("/:foo/bar/:glob", :glob => /.*/).register
      end
      
      %w(somewhere somewhere/somehow 123/456/789 i;just/dont-understand).each do |path|
        route_for("/superblog/bar/#{path}").should have_route(:foo => "superblog", :glob => path)
        lambda { route_for("/notablog/foo/#{path}") }.should raise_not_found
      end
    end
    
    it "should match only if all mixed conditions are satisied" do
      Merb::Router.prepare do
        match("/:blog/post/:id", :blog => %r{^[a-zA-Z]+$}, :id => %r{^[0-9]+$}).register
      end
      
      route_for("/superblog/post/123").should  have_route(:blog => "superblog",  :id => "123")
      route_for("/superblawg/post/321").should have_route(:blog => "superblawg", :id => "321")
      lambda { route_for("/superblog/post/asdf") }.should raise_not_found
      lambda { route_for("/superblog1/post/123") }.should raise_not_found
      lambda { route_for("/ab/12") }.should raise_not_found
    end
  end
  
  describe "a route built with nested conditions" do
    
    it "should support block matchers as a path namespace" do
      Merb::Router.prepare do
        match("/foo") do
          match("/bar").to(:controller => "one/two", :action => "baz")
        end
      end
      
      route_for("/foo/bar").should have_route(:controller => "one/two", :action => "baz")
    end
    
    it "should yield the builder object" do
      Merb::Router.prepare do
        match("/foo") do |path|
          path.match("/bar").to(:controller => "one/two", :action => "baz")
        end
      end
      
      route_for("/foo/bar").should have_route(:controller => "one/two", :action => "baz")
    end
    
    it "should be able to nest named segment variables" do
      Merb::Router.prepare do
        match("/:first") do
          match("/:second").register
        end
      end
      
      route_for("/one/two").should have_route(:first => "one", :second => "two")
      lambda { route_for("/one") }.should raise_not_found
    end
    
    it "should ignore trailing slashes" do
      Merb::Router.prepare do
        match("/hello") do
          match("/").to(:controller => "greetings")
        end
      end
      
      route_for("/hello").should have_route(:controller => "greetings")
    end
    
    it "should ignore double slashes" do
      Merb::Router.prepare do
        match("/hello/") do
          match("/world").to(:controller => "greetings")
        end
      end
      
      route_for("/hello/world").should have_route(:controller => "greetings")
    end
    
    it "should be able to define a route and still use the context for more route definition" do
      Merb::Router.prepare do
        match("/hello") do
          to(:controller => "foo", :action => "bar")
          match("/world").to(:controller => "hello", :action => "world")
        end
      end
      
      route_for("/hello").should have_route(:controller => "foo", :action => "bar")
      route_for("/hello/world").should have_route(:controller => "hello", :action => "world")
    end
    
    it "should be able to add blank paths without effecting the actual path" do
      Merb::Router.prepare do
        match("/foo") do
          match("").to(:controller => "one/two", :action => "index")
        end
      end
      
      route_for("/foo").should have_route(:controller => "one/two", :action => "index")
    end
    
    it "should be able to merge path and request method conditions" do
      Merb::Router.prepare do
        match("/:controller") do
          match(:protocol => "https").to(:action => "bar")
        end
      end
      
      lambda { route_for("/foo") }.should raise_not_found
      route_for("/foo", :protocol => "https").should have_route(:controller => "foo", :action => "bar")
    end
    
    it "should be able to override previously set Request method conditions" do
      Merb::Router.prepare do
        match(:domain => "foo.com") do
          match("/", :domain => "bar.com").to(:controller => "bar", :action => "com")
        end
      end
      
      lambda { route_for("/") }.should raise_not_found
      lambda { route_for("/", :domain => "foo.com") }.should raise_not_found
      route_for("/", :domain => "bar.com").should have_route(:controller => "bar", :action => "com")
    end
    
    it "should be able to override previously set named segment variable conditions" do
      Merb::Router.prepare do
        match("/:account", :account => /^\d+$/) do
          match(:account => /^[a-z]+$/).register
        end
      end
      
      route_for("/abc").should have_route(:account => "abc")
      lambda { route_for("/123") }.should raise_not_found
    end
    
    it "should be able to set conditions on named segment variables that haven't been used yet" do
      Merb::Router.prepare do
        match(:account => /^[a-z]+$/) do
          match("/:account").register
        end
      end
      
      route_for("/abc").should have_route(:account => "abc")
      lambda { route_for("/123") }.should raise_not_found
    end
    
    it "should be able to merge path and request method conditions when both kinds are specified in the parent match statement" do
      Merb::Router.prepare do
        match("/:controller", :protocol => "https") do
          match("/greets").to(:action => "bar")
        end
      end
      
      lambda { route_for("/foo") }.should raise_not_found
      lambda { route_for("/foo/greets") }.should raise_not_found
      lambda { route_for("/foo", :protocol => "https") }.should raise_not_found
      route_for("/foo/greets", :protocol => "https").should have_route(:controller => "foo", :action => "bar")
    end
    
    it "allows wrapping of nested routes all having shared argument with PREDEFINED VALUES" do
      Merb::Router.prepare do
        match(%r{/?(en|es|fr|be|nl)?}).to(:language => "[1]") do
          match("/guides/:action/:id").to(:controller => "tour_guides")
        end
      end

      route_for('/nl/guides/search/denboss').should   have_route(:controller => 'tour_guides', :action => "search", :id => "denboss", :language => "nl")
      route_for('/es/guides/search/barcelona').should have_route(:controller => 'tour_guides', :action => "search", :id => "barcelona", :language => "es")
      route_for('/fr/guides/search/lille').should     have_route(:controller => 'tour_guides', :action => "search", :id => "lille", :language => "fr")
      route_for('/en/guides/search/london').should    have_route(:controller => 'tour_guides', :action => "search", :id => "london", :language => "en")
      route_for('/be/guides/search/brussels').should  have_route(:controller => 'tour_guides', :action => "search", :id => "brussels", :language => "be")
      route_for('/guides/search/brussels').should     have_route(:controller => 'tour_guides', :action => "search", :id => "brussels")
    end
    
  end

  describe "multiple routes" do
    # --- Catches a weird bug ---
    it "should not leak conditions" do
      Merb::Router.prepare do
        match("/root") do |r|
          r.match('/foo').to
          r.match('/bar').to(:hello => "world")
        end
      end
      
      route_for("/root/bar").should have_route(:hello => "world")
    end
  end
end