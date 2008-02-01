require File.dirname(__FILE__) + '/../../spec_helper'
require "date"

describe Hash, "environmentize_keys!" do
  it "should transform keys to uppercase text" do
    { :test_1  => 'test', 'test_2' => 'test', 1 => 'test' }.environmentize_keys!.should ==
      { 'TEST_1' => 'test', 'TEST_2' => 'test', '1' => 'test' }
  end
  
  it "should only transform one level of keys" do
    { :test_1  => { :test2 => 'test'} }.environmentize_keys!.should == 
      { 'TEST_1' => { :test2 => 'test'} }
  end
end

describe Hash, "only" do
  before do
    @hash = { :one => 'ONE', 'two' => 'TWO', 3 => 'THREE' }
  end
  
  it "should return a hash with only the given key(s)" do
    @hash.only(:one).should == { :one => 'ONE' }
    @hash.only(:one, 3).should == { :one => 'ONE', 3 => 'THREE' }
  end
end

describe Hash, "except" do
  before do
    @hash = { :one => 'ONE', 'two' => 'TWO', 3 => 'THREE' }
  end
  
  it "should return a hash without only the given key(s)" do
    @hash.except(:one).should == { 'two' => 'TWO', 3 => 'THREE' }
    @hash.except(:one, 3).should == { 'two' => 'TWO' }
  end
end

describe Hash, "symbolize_keys!" do
  before do
    @hash = { 'one' => 1, 'two' => 2 }
    @hash_with_another_hash = { 'a' => 'A', 'prefs' => { 'private' => true, 'sex' => 'yes please' } }
    @hash_with_non_string_keys = { 'one' => 1, 2 => 'TWO', '' => 'blank' }
  end
  
  it "should convert all keys to symbols" do
    @hash.symbolize_keys!
    @hash.should == { :one => 1, :two => 2 }
  end
  
  it "should recursively convert all keys to symbols" do
    @hash_with_another_hash.symbolize_keys!
    @hash_with_another_hash.should == { :a => 'A', :prefs => { :private => true, :sex => 'yes please' } }
  end
end

describe Hash, "to_xml_attributes" do
  before do
    @hash = { :one => "ONE", "two" => "TWO" }
  end
  
  it "should turn the hash into xml attributes" do
    attrs = @hash.to_xml_attributes
    attrs.should match(/one="ONE"/m)
    attrs.should match(/two="TWO"/m)
  end
end

describe Hash, "from_xml" do
  it "should transform a simple tag with content" do
    xml = "<tag>This is the contents</tag>"
    Hash.from_xml(xml).should == { 'tag' => 'This is the contents' }
  end
  
  it "should work with cdata tags" do
    xml = <<-END
      <tag>
      <![CDATA[
        text inside cdata
      ]]>
      </tag>
    END
    Hash.from_xml(xml)["tag"].strip.should == "text inside cdata"
  end
  
  it "should transform a simple tag with attributes" do
    xml = "<tag attr1='1' attr2='2'></tag>"
    hash = { 'tag' => { 'attr1' => '1', 'attr2' => '2' } }
    Hash.from_xml(xml).should == hash
  end  
  
  it "should transform repeating siblings into an array" do
    xml =<<-XML
      <opt>
        <user login="grep" fullname="Gary R Epstein" />
        <user login="stty" fullname="Simon T Tyson" />
      </opt>
    XML
    
    Hash.from_xml(xml)['opt']['user'].should be_an_instance_of(Array)
    
    hash = {
      'opt' => {
        'user' => [{
          'login'    => 'grep',
          'fullname' => 'Gary R Epstein'
        },{
          'login'    => 'stty',
          'fullname' => 'Simon T Tyson'
        }]
      }
    }
    
    Hash.from_xml(xml).should == hash
  end
  
  it "should not transform non-repeating siblings into an array" do
    xml =<<-XML
      <opt>
        <user login="grep" fullname="Gary R Epstein" />
      </opt>
    XML
      
    Hash.from_xml(xml)['opt']['user'].should be_an_instance_of(Hash)
    
    hash = {
      'opt' => { 
        'user' => { 
          'login' => 'grep', 
          'fullname' => 'Gary R Epstein'
        }
      }
    }
    
    Hash.from_xml(xml).should == hash
  end
  
  it "should typecast an integer" do
    xml = "<tag type='integer'>10</tag>"
    Hash.from_xml(xml)['tag'].should == 10
  end
  
  it "should typecast a true boolean" do
    xml = "<tag type='boolean'>true</tag>"
    Hash.from_xml(xml)['tag'].should be_true
  end
  
  it "should typecast a false boolean" do
    ["false", "1", "0", "some word" ].each do |w|
      Hash.from_xml("<tag type='boolean'>#{w}</tag>")['tag'].should be_false
    end
  end
  
  it "should typecast a datetime" do
    xml = "<tag type='datetime'>2007-12-31 10:32</tag>"
    Hash.from_xml(xml)['tag'].should == Time.parse( '2007-12-31 10:32' ).utc
  end
  
  it "should typecast a date" do
    xml = "<tag type='date'>2007-12-31</tag>"
    Hash.from_xml(xml)['tag'].should == Date.parse('2007-12-31')
  end
  
  it "should unescape html entities" do
    values = {
      "<" => "&lt;",
      ">" => "&gt;",
      '"' => "&quot;",
      "'" => "&apos;",
      "&" => "&amp;"
    }
    values.each do |k,v|
      xml = "<tag>Some content #{v}</tag>"
      Hash.from_xml(xml)['tag'].should match(Regexp.new(k))
    end
  end
  
  it "should undasherize keys as tags" do
    xml = "<tag-1>Stuff</tag-1>"
    Hash.from_xml(xml).keys.should include( 'tag_1' )
  end
  
  it "should undasherize keys as attributes" do
    xml = "<tag1 attr-1='1'></tag1>"
    Hash.from_xml(xml)['tag1'].keys.should include( 'attr_1')
  end
  
  it "should undasherize keys as tags and attributes" do
    xml = "<tag-1 attr-1='1'></tag-1>"
    Hash.from_xml(xml).keys.should include( 'tag_1' )
    Hash.from_xml(xml)['tag_1'].keys.should include( 'attr_1')
  end
  
  it "should render nested content correctly" do
    xml = "<root><tag1>Tag1 Content <em><strong>This is strong</strong></em></tag1></root>"
    Hash.from_xml(xml)['root']['tag1'].should == "Tag1 Content <em><strong>This is strong</strong></em>"
  end
  
  it "should render nested content with split text nodes correctly" do
    xml = "<root>Tag1 Content<em>Stuff</em> Hi There</root>"
    Hash.from_xml(xml)['root'].should == "Tag1 Content<em>Stuff</em> Hi There"
  end
  
  it "should ignore attributes when a child is a text node" do
    xml = "<root attr1='1'>Stuff</root>"
    Hash.from_xml(xml).should == { "root" => "Stuff" }
  end
  
  it "should ignore attributes when any child is a text node" do
    xml = "<root attr1='1'>Stuff <em>in italics</em></root>"
    Hash.from_xml(xml).should == { "root" => "Stuff <em>in italics</em>" }
  end
  
  it "should correctly transform multiple children" do
    xml = <<-XML
    <user gender='m'>
      <age type='integer'>35</age>
      <name>Home Simpson</name>
      <dob type='date'>1988-01-01</dob>
      <joined-at type='datetime'>2000-04-28 23:01</joined-at>
      <is-cool type='boolean'>true</is-cool>
    </user>
    XML
    
    hash =  {
      "user" => {
        "gender"    => "m",
        "age"       => 35,
        "name"      => "Home Simpson",
        "dob"       => Date.parse('1988-01-01'),
        "joined_at" => Time.parse("2000-04-28 23:01"),
        "is_cool"   => true
      }
    }
    
    Hash.from_xml(xml).should == hash
  end
end

describe Hash, 'to_params' do
  before do
    @hash = { :name => 'Bob', :address => { :street => '111 Ruby Ave.', :city => 'Ruby Central', :phones => ['111-111-1111', '222-222-2222'] } }
  end
  
  it 'should convert correctly into query parameters' do
    @hash.to_params.split('&').sort.should ==
      'name=Bob&address[city]=Ruby Central&address[phones]=111-111-1111222-222-2222&address[street]=111 Ruby Ave.'.split('&').sort
  end
  
  it 'should not leave a trailing &' do
    @hash.to_params.should_not match(/&$/)
  end
end