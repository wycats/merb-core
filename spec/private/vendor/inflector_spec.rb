require File.dirname(__FILE__) + '/../../spec_helper'

describe Language::English::Inflect, "#singular" do
  # ==== Singularization: exceptional cases

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

  # used to be a bug exposed by this specs suite,
  # this MUST pass or we've got regression
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

  it "singularizes octopi => octopus" do
    "octopi".singular.should == "octopus"
  end

  it "singularizes grass => grass" do
    "grass".singular.should == "grass"
  end

  it "singularizes phenomena => phenomenon" do
    "phenomena".singular.should == "phenomenon"
  end





  # ==== Singularization: bugs, typos and reported issues

  # LH ticket #318 for merb-core
  it "singularizes forum => forum" do
    "forum".singular.should == "forum"
  end





  # ==== Singularization: rules

  it "singularizes forums => forum" do
    "forums".singular.should == "forum"
  end

  it "singularizes hives => hive" do
    "hives".singular.should == "hive"
  end

  it "singularizes athletes => athlete" do
    "athletes".singular.should == "athlete"
  end

  it "singularizes dwarves => dwarf" do
    "dwarves".singular.should == "dwarf"
  end

  it "singularizes heroes => hero" do
    "heroes".singular.should == "hero"
  end

  it "singularizes zeroes => zero" do
    "zeroes".singular.should == "zero"
  end

  it "singularizes men => man" do
    "men".singular.should == "man"
  end

  it "singularizes women => woman" do
    "women".singular.should == "woman"
  end

  it "singularizes sportsmen => sportsman" do
    "sportsmen".singular.should == "sportsman"
  end

  it "singularizes branches => branch" do
    "branches".singular.should == "branch"
  end

  it "singularizes crunches => crunch" do
    "crunches".singular.should == "crunch"
  end

  it "singularizes trashes => trash" do
    "trashes".singular.should == "trash"
  end

  it "singularizes mashes => mash" do
    "mashes".singular.should == "mash"
  end

  it "singularizes errata => erratum" do
    "errata".singular.should == "erratum"
  end



  it "singularizes foxes => fox" do
    "foxes".singular.should == "fox"
  end

  it "singularizes flies => fly" do
    "flies".singular.should == "fly"
  end

  it "singularizes rays => ray" do
    "rays".singular.should == "ray"
  end

  it "singularizes sprays => spray" do
    "sprays".singular.should == "spray"
  end

  it "singularizes cats => cat" do
    "cats".singular.should == "cat"
  end

  it "singularizes rats => rat" do
    "rats".singular.should == "rat"
  end
end
