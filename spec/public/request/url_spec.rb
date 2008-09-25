require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

class Monkey ; def to_param ; 45 ; end ; end
class Donkey ; def to_param ; 19 ; end ; end
class Blue
  def to_param ; 13 ; end
  def monkey_id ; Monkey.new ; end
  def donkey_id ; Donkey.new ; end
end
class Pink
  def to_param ; 22 ; end
  def blue_id ; Blue.new ; end
  def monkey_id ; blue_id.monkey_id ; end
end

describe Merb::Request, " url" do
  
  before(:each) do
    Merb::Router.prepare do |r|
      identify :to_param do
        r.resources :monkeys do |m|
          m.resources :blues do |b|
            b.resources :pinks
          end
        end
        r.resources :donkeys do |d|
          d.resources :blues
        end
        r.resource :red do |red|
          red.resources :blues
        end
        r.match(%r{/foo/(\d+)/}).to(:controller => 'asdf').name(:regexp)
        r.match('/people(/:name)(.:format)').to(:controller => 'people', :action => 'show').name(:person)
        r.match('/argstrs').to(:controller => "args").name(:args)
        r.default_routes
      end
    end
    
    @request = fake_request
  end
  
  it "should match the :controller to the default route" do
    @request.generate_url(:controller => "monkeys").should eql("/monkeys")
  end

  it "should match the :controller,:action to the default route" do
    @request.generate_url(:controller => "monkeys", :action => "list").
      should eql("/monkeys/list")
  end
  
  it "should match the :controller,:action,:id to the default route" do
    @request.generate_url(:controller => "monkeys", :action => "list", :id => 4).
      should eql("/monkeys/list/4")
  end
  
  it "should match the :controller,:action,:id,:format to the default route" do
    @request.generate_url(:controller => "monkeys", :action => "list", :id => 4, :format => "xml").
      should eql("/monkeys/list/4.xml")
  end
  
  it "should match the :controller,:action,:id,:format,:fragment to the default route" do
    @request.generate_url(:controller => "monkeys", :action => "list", :id => 4, :format => "xml", :fragment => :half_way).
      should eql("/monkeys/list/4.xml#half_way")
  end

  it "should raise an error when trying to generate a regexp route" do
    lambda { @request.generate_url(:regexp) }.should raise_error(Merb::Router::GenerationError)
  end
  
  it "should raise an error when trying to generate a route that doesn't exist" do
    lambda { @request.generate_url(:lalalala) }.should raise_error(Merb::Router::GenerationError)
  end

  it "should match with a route param" do
    @request.generate_url(:person, :name => "david").should eql("/people/david")
  end

  it "should match without a route param" do
    @request.generate_url(:person).should eql("/people")
  end

  it "should match with an additional param" do
    @request.generate_url(:person, :name => 'david', :color => 'blue').should eql("/people/david?color=blue")
  end
  
  it "should match with a :format" do
    @request.generate_url(:person, :name => 'david', :format => :xml).should eql("/people/david.xml")
  end
  
  it "should match with a :fragment" do
    @request.generate_url(:person, :name => 'david', :fragment => :half_way).should eql("/people/david#half_way")
  end
  
  it "should match with an additional param and :format" do
    @request.generate_url(:person, :name => 'david', :color => 'blue', :format => :xml).should eql("/people/david.xml?color=blue")
  end
  
  it "should match with an additional param, :format, and :fragment" do
    @request.generate_url(:person, :name => 'david', :color => 'blue', :format => :xml, :fragment => :half_way).
      should eql("/people/david.xml?color=blue#half_way")
  end
  
  it "should match with additional params" do
    url = @request.generate_url(:person, :name => 'david', :smell => 'funky', :color => 'blue')
    url.should match(%r{/people/david?.*color=blue})
    url.should match(%r{/people/david?.*smell=funky})
  end

  it "should match with extra params and an array" do
    @request.generate_url(:args, :monkey => [1,2]).should == "/argstrs?monkey[]=1&monkey[]=2"
  end
  
  it "should match with no second arg" do
    @request.generate_url(:monkeys).should == "/monkeys"
  end
  
  it "should match with an object as second arg" do
    @monkey = Monkey.new
    @request.generate_url(:monkey, @monkey).should == "/monkeys/45"
  end
  
  it "should match with a fixnum as second arg" do
    @request.generate_url(:monkey, 3).should == "/monkeys/3"
  end
  
  it "should match with an object and :format" do
    @monkey = Monkey.new
    @request.generate_url(:monkey, :id => @monkey, :format => :xml).should == "/monkeys/45.xml"
  end
  
  it "should match with an object, :format and additional options" do
    @monkey = Monkey.new
    @request.generate_url(:monkey, :id => @monkey, :format => :xml, :color => "blue").should == "/monkeys/45.xml?color=blue"
  end
  
  it "should match with an object, :format, :fragment, and additional options" do
    @monkey = Monkey.new
    @request.generate_url(:monkey, :id => @monkey, :format => :xml, :color => "blue", :fragment => :half_way).should == "/monkeys/45.xml?color=blue#half_way"
  end

  it "should match the delete_monkey route" do
    @monkey = Monkey.new
    @request.generate_url(:delete_monkey, @monkey).should == "/monkeys/45/delete"
  end
  
  it "should match the delete_red route" do
    @request.generate_url(:delete_red).should == "/red/delete"
  end

  it "should add a path_prefix to the url if :path_prefix is set" do
    Merb::Config[:path_prefix] = "/jungle"
    @request.generate_url(:monkeys).should == "/jungle/monkeys"
    Merb::Config[:path_prefix] = nil
  end
 
  it "should match a nested resources show action" do
    @blue = Blue.new
    @request.generate_url(:monkey_blue, @blue.monkey_id, @blue).should == "/monkeys/45/blues/13"
  end
  
  it "should match the index action of nested resource with parent object" do
    @blue = Blue.new
    @monkey = Monkey.new
    @request.generate_url(:monkey_blues, :monkey_id => @monkey).should == "/monkeys/45/blues"
  end
  
  it "should match the index action of nested resource with parent id as string" do
    @blue = Blue.new
    @request.generate_url(:monkey_blues, :monkey_id => '1').should == "/monkeys/1/blues"
  end
  
  it "should match the edit action of nested resource" do
    @blue = Blue.new
    @request.generate_url(:edit_monkey_blue, @blue.monkey_id, @blue).should == "/monkeys/45/blues/13/edit"
  end
  
  it "should match the index action of resources nested under a resource" do
    @blue = Blue.new
    @request.generate_url(:red_blues).should == "/red/blues"
  end
  
  it "should match resource that has been nested multiple times" do
    @blue = Blue.new
    @request.generate_url(:donkey_blue, @blue.donkey_id, @blue).should == "/donkeys/19/blues/13"
    @request.generate_url(:monkey_blue, @blue.monkey_id, @blue).should == "/monkeys/45/blues/13"
  end
  
  it "should match resources nested more than one level deep" do
    @pink = Pink.new
    @request.generate_url(:monkey_blue_pink, @pink.blue_id.monkey_id, @pink.blue_id, @pink).should == "/monkeys/45/blues/13/pinks/22"
  end

  it "should match resource with additional params" do
    @monkey = Monkey.new
    @request.generate_url(:monkey, @monkey, :foo => "bar").should == "/monkeys/45?foo=bar"
  end
  it "should match resource with fragment" do
    @monkey = Monkey.new
    @request.generate_url(:monkey, @monkey, :fragment => :half_way).should == "/monkeys/45#half_way"
  end

  it "should match a nested resource with additional params" do
    @blue = Blue.new
    @request.generate_url(:monkey_blue, @blue.monkey_id, @blue, :foo => "bar").should == "/monkeys/45/blues/13?foo=bar"
  end
  
  it "should match a nested resource with additional params and fragment" do
    @blue = Blue.new
    @request.generate_url(:monkey_blue, @blue.monkey_id, @blue, :foo => "bar", :fragment => :half_way).should == "/monkeys/45/blues/13?foo=bar#half_way"
  end

end




describe Merb::Request, "absolute_url" do
  before do
    @request = fake_request
  end

  it 'takes :protocol option' do
    @monkey = Monkey.new
    @request.generate_absolute_url(:monkey,
                             :id       => @monkey,
                             :format   => :xml,
                             :protocol => "https").should == "https://localhost/monkeys/45.xml"
  end

  it 'takes :host option' do
    @monkey = Monkey.new
    @request.generate_absolute_url(:monkey,
                             :id       => @monkey,
                             :format   => :xml,
                             :protocol => "https",
                             :host     => "rubyisnotrails.org").should == "https://rubyisnotrails.org/monkeys/45.xml"
  end

  it 'falls back to request protocol' do
    @monkey = Monkey.new
    @request.generate_absolute_url(:monkey,
                             :id       => @monkey,
                             :format   => :xml).should == "http://localhost/monkeys/45.xml"
  end

  it 'falls back to request host' do
    @monkey = Monkey.new
    @request.generate_absolute_url(:monkey,
                             :id       => @monkey,
                             :format   => :xml,
                             :protocol => "https").should == "https://localhost/monkeys/45.xml"
  end
  
  it "allows passing an object instead of a hash" do
    @monkey = Monkey.new
    @request.generate_absolute_url(:monkey, @monkey).should == "http://localhost/monkeys/45"
  end
  
end
