require File.dirname(__FILE__) + '/../../spec_helper'

describe Language::English::Inflect, "#singular" do
  before :each do

  end

  it "handles regular cases"

  it "singularizes equipment => equipment" do
    "equipment".singular.should == "equipment"
  end

  it "singularizes information => information" do
    "information".singular.should == "information"
  end

  it "singularizes money => money" do
    "money".singular.should == "money"
  end

  it "singularizes species => species" do
    "species".singular.should == "species"
  end

  it "singularizes series => series" do
    "series".singular.should == "series"
  end

  it "singularizes fish => fish" do
    "fish".singular.should == "fish"
  end

  it "singularizes sheep => sheep" do
    "sheep".singular.should == "sheep"
  end

  it "singularizes moose => moose" do
    "moose".singular.should == "moose"
  end

  it "singularizes hovercraft => hovercraft" do
    "hovercraft".singular.should == "hovercraft"
  end

  it "singularizes cactus => cacti" do
    "cacti".singular.should == "cactus"
  end

  it "singularizes matrices => matrix" do
    "matrices".singular.should == "matrix"
  end

  it "singularizes Swiss => Swiss" do
    "Swiss".singular.should == "Swiss"
  end

  it "singularizes lives => life" do
    "lives".singular.should == "life"
  end

  it "singularizes wives => wife" do
    "wives".singular.should == "wife"
  end

  it "singularizes geese => goose" do
    "geese".singular.should == "goose"
  end

  it "singularizes criteria => criterion" do
    "criteria".singular.should == "criterion"
  end

  it "singularizes aliases => alias" do
    "aliases".singular.should == "alias"
  end

  it "singularizes statuses => status" do
    "statuses".singular.should == "status"
  end

  it "singularizes axes => axis" do
    "axes".singular.should == "axis"
  end

  it "singularizes crises => crisis" do
    "crises".singular.should == "crisis"
  end

  it "singularizes testes => testis" do
    "testes".singular.should == "testis"
  end

  it "singularizes children => child" do
    "children".singular.should == "child"
  end

  it "singularizes people => person" do
    "people".singular.should == "person"
  end

  it "singularizes potatoes => potato" do
    "potatoes".singular.should == "potato"
  end

  it "singularizes tomatoes => tomato" do
    "tomatoes".singular.should == "tomato"
  end

  it "singularizes buffaloes => buffalo" do
    "buffaloes".singular.should == "buffalo"
  end

  it "singularizes torpedoes => torpedo" do
    "torpedoes".singular.should == "torpedo"
  end

  it "singularizes quizes => quiz" do
    "quizes".singular.should == "quiz"
  end

  # bug exposed by this specs suite, this MUST pass
  it "singularizes vertices => vertex" do
    "vertices".singular.should == "vertex"
  end

  it "singularizes indices => index" do
    "indices".singular.should == "index"
  end

  it "singularizes oxen => ox" do
    "oxen".singular.should == "ox"
  end

  it "singularizes mice => mouse" do
    "mice".singular.should == "mouse"
  end

  it "singularizes lice => louse" do
    "lice".singular.should == "louse"
  end

  it "singularizes theses => thesis" do
    "theses".singular.should == "thesis"
  end

  it "singularizes thieves => thief" do
    "thieves".singular.should == "thief"
  end

  it "singularizes analyses => analysis" do
    "analyses".singular.should == "analysis"
  end

  it "singularizes forums => forum" do
    "forums".singular.should == "forum"
  end

  # LH ticket #318 for merb-core
  it "singularizes forum => forum" do
    "forum".singular.should == "forum"
  end
end
