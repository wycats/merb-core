require "rubygems"
require "dm-core"
require "dm-validations"
require "pp"

DataMapper.setup(:default, "sqlite3::memory:")

class Category
  include DataMapper::Resource
  
  property :id, Serial
  has n, :items
end

class Item
  include DataMapper::Resource

  property :id, Serial
  property :category_id, Integer
  belongs_to :category
end

DataMapper.auto_migrate!

Item.create(:category_id => 25)
Item.first.category

# class Parent
#   include DataMapper::Resource
#     
#   property :id, Serial
#   property :name, String
#   
#   def self.auto_migrate!(*args)
#     nil
#   end
# end
# 
# class Child1 < Parent
#   property :child_attr1, String
#   validates_present :name
# end
# 
# class Child2 < Parent
#   property :child_attr2, String
# end
# 
# DataMapper.auto_migrate!
# 
# describe Parent do
#   it "has an id" do
#     Parent.properties.map {|x| x.name}.should include(:id)
#   end
#   
#   it "doesn't have a child_attr1" do
#     Parent.properties.map {|x| x.name}.should_not include(:child_attr1)
#   end
#   
#   it "has a name non-nullable validation" do
#     Parent.validators.contexts[:default].select do |obj|
#       obj.field_name == :name
#     end.any? {|v| v.is_a?(DataMapper::Validate::RequiredFieldValidator)}.
#       should be_false
#   end
# end
# 
# describe Child1 do
#   it "has an id" do
#     Child1.properties.map {|x| x.name}.should include(:id)
#   end
#   
#   it "has a child_attr1" do
#     Child1.properties.map {|x| x.name}.should include(:child_attr1)
#   end
#   
#   it "doesn't have a child_attr2" do
#     Child1.properties.map {|x| x.name}.should_not include(:child_attr2)
#   end
#   
#   it "has a name non-nullable validation" do
#     Child1.validators.contexts[:default].select do |obj|
#       obj.field_name == :name
#     end.any? {|v| v.is_a?(DataMapper::Validate::RequiredFieldValidator)}.
#       should be_true
#   end
# end