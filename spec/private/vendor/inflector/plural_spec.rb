require File.dirname(__FILE__) + '/../../../spec_helper'

describe Language::English::Inflect, "#plural" do
  it "pluralizes equipment => equipment" do
    "equipment".plural.should == "equipment"
  end

  it "pluralizes information => information" do
    "information".plural.should == "information"
  end

  it "pluralizes money => money" do
    "money".plural.should == "money"
  end

  it "pluralizes species => species" do
    "species".plural.should == "species"
  end

  it "pluralizes series => series" do
    "series".plural.should == "series"
  end

  it "pluralizes fish => fish" do
    "fish".plural.should == "fish"
  end

  it "pluralizes sheep => sheep" do
    "sheep".plural.should == "sheep"
  end

  it "pluralizes moose => moose" do
    "moose".plural.should == "moose"
  end

  it "pluralizes rain => rain" do
    "rain".plural.should == "rain"
  end

  it "pluralizes hovercraft => hovercraft" do
    "hovercraft".plural.should == "hovercraft"
  end

  it "pluralizes grass => grass" do
    "grass".plural.should == "grass"
  end

  it "pluralizes news => news" do
    "news".plural.should == "news"
  end

  it "pluralizes Swiss => Swiss" do
    "Swiss".plural.should == "Swiss"
  end

  it "pluralizes milk => milk" do
    "milk".plural.should == "milk"
  end

  it "pluralizes life => lives" do
    "life".plural.should == "lives"
  end

  it "pluralizes wife => wives" do
    "wife".plural.should == "wives"
  end

  it "pluralizes goose => geese" do
    "goose".plural.should == "geese"
  end

  it "pluralizes criterion => criteria" do
    "criterion".plural.should == "criteria"
  end

  it "pluralizes alias => aliases" do
    "alias".plural.should == "aliases"
  end

  it "pluralizes status => statuses" do
    "status".plural.should == "statuses"
  end

  it "pluralizes axis => axes" do
    "axis".plural.should == "axes"
  end

  it "pluralizes crisis => crises" do
    "crisis".plural.should == "crises"
  end

  it "pluralizes testis => testes" do
    "testis".plural.should == "testes"
  end

  it "pluralizes child => children" do
    "child".plural.should == "children"
  end

  it "pluralizes person => people" do
    "person".plural.should == "people"
  end

  it "pluralizes potato => potatoes" do
    "potato".plural.should == "potatoes"
  end

  it "pluralizes tomato => tomatoes" do
    "tomato".plural.should == "tomatoes"
  end

  it "pluralizes buffalo => buffaloes" do
    "buffalo".plural.should == "buffaloes"
  end

  it "pluralizes torpedo => torpedoes" do
    "torpedo".plural.should == "torpedoes"
  end

  it "pluralizes quiz => quizes" do
    "quiz".plural.should == "quizes"
  end

  it "pluralizes matrix => matrices" do
    "matrix".plural.should == "matrices"
  end

  it "pluralizes vertex => vertices" do
    "vertex".plural.should == "vertices"
  end

  it "pluralizes index => indeces" do
    "index".plural.should == "indeces"
  end

  it "pluralizes ox => oxen" do
    "ox".plural.should == "oxen"
  end

  it "pluralizes mouse => mice" do
    "mouse".plural.should == "mice"
  end

  it "pluralizes louse => lice" do
    "louse".plural.should == "lice"
  end

  it "pluralizes thesis => theses" do
    "thesis".plural.should == "theses"
  end

  it "pluralizes thief => thieves" do
    "thief".plural.should == "thieves"
  end

  it "pluralizes analysis => analyses" do
    "analysis".plural.should == "analyses"
  end

  it "pluralizes erratum => errata" do
    "erratum".plural.should == "errata"
  end

  it "pluralizes phenomenon => phenomena" do
    "phenomenon".plural.should == "phenomena"
  end

  it "pluralizes octopus => octopi" do
    "octopus".plural.should == "octopi"
  end

  it "pluralizes thesaurus => thesauri" do
    "thesaurus".plural.should == "thesauri"
  end

  it "pluralizes movie => movies" do
    "movie".plural.should == "movies"
  end
end
