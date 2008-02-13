module Language

module English

  # = English Nouns Number Inflection.
  #
  # This module provides english singular <-> plural noun inflections.
  module Inflect

    @singular_of = {}
    @plural_of = {}

    @singular_rules = []
    @plural_rules = []

    class << self
      # Define a general exception.
      def word(singular, plural=nil)
        plural = singular unless plural
        singular_word(singular, plural)
        plural_word(singular, plural)
      end

      # Define a singularization exception.
      def singular_word(singular, plural)
        @singular_of[plural] = singular
      end

      # Define a pluralization exception.
      def plural_word(singular, plural)
        @plural_of[singular] = plural
      end

      # Define a general rule.
      def rule(singular, plural)
        singular_rule(singular, plural)
        plural_rule(singular, plural)
      end

      # Define a singularization rule.
      def singular_rule(singular, plural)
        @singular_rules << [singular, plural]
      end

      # Define a plurualization rule.
      def plural_rule(singular, plural)
        @plural_rules << [singular, plural]
      end

      # Read prepared singularization rules.
      def singularization_rules
        return @singularization_rules if @singularization_rules
        sorted = @singular_rules.sort_by{ |s, p| "#{p}".size }.reverse
        @singularization_rules = sorted.collect do |s, p|
          [ /#{p}$/, "#{s}" ]
        end
      end

      # Read prepared pluralization rules.
      def pluralization_rules
        return @pluralization_rules if @pluralization_rules
        sorted = @plural_rules.sort_by{ |s, p| "#{s}".size }.reverse
        @pluralization_rules = sorted.collect do |s, p|
          [ /#{s}$/, "#{p}" ]
        end
      end

      #
      def plural_of
        @plural_of
      end

      #
      def singular_of
        @singular_of
      end

      # Convert an English word from plurel to singular.
      #
      #   "boys".singular      #=> boy
      #   "tomatoes".singular  #=> tomato
      #
      def singular(word)
        if result = singular_of[word]
          return result.dup
        end
        result = word.dup
        singularization_rules.each do |(match, replacement)|
          break if result.gsub!(match, replacement)
        end
        return result
      end

      # Alias for #singular (a Railism).
      #
      alias_method(:singularize, :singular)

      # Convert an English word from singular to plurel.
      #
      #   "boy".plural     #=> boys
      #   "tomato".plural  #=> tomatoes
      #
      def plural(word)
        if result = plural_of[word]
          return result.dup
        end
        #return self.dup if /s$/ =~ self # ???
        result = word.dup
        pluralization_rules.each do |(match, replacement)|
          break if result.gsub!(match, replacement)
        end
        return result
      end

      # Alias for #plural (a Railism).
      alias_method(:pluralize, :plural)
    end

    # One argument means singular and plural are the same.

    word 'equipment'
    word 'information'
    word 'money'
    word 'species'
    word 'series'
    word 'fish'
    word 'sheep'
    word 'moose'
    word 'hovercraft'

    # Two arguments defines a singular and plural exception.

    word 'Swiss'     , 'Swiss'
    word 'life'      , 'lives'
    word 'wife'      , 'wives'
    word 'goose'     , 'geese'
    word 'criterion' , 'criteria'
    word 'alias'     , 'aliases'
    word 'status'    , 'statuses'
    word 'axis'      , 'axes'
    word 'crisis'    , 'crises'
    word 'testis'    , 'testes'
    word 'child'     , 'children'
    word 'person'    , 'people'
    word 'potato'    , 'potatoes'
    word 'tomato'    , 'tomatoes'
    word 'buffalo'   , 'buffaloes'
    word 'torpedo'   , 'torpedoes'
    word 'quiz'      , 'quizes'
    word 'matrix'    , 'matrices'
    word 'vertex'    , 'vetices'
    word 'index'     , 'indices'
    word 'ox'        , 'oxen'
    word 'mouse'     , 'mice'
    word 'louse'     , 'lice'
    word 'thesis'    , 'theses'
    word 'thief'     , 'thieves'
    word 'analysis'  , 'analyses'

    # One-way singularization exception (convert plural to singular).

    singular_word 'cactus', 'cacti'

    # General rules.

    rule 'hive' , 'hives'
    rule 'rf'   , 'rves'
    rule 'af'   , 'aves'
    rule 'ero'  , 'eroes'
    rule 'man'  , 'men'
    rule 'ch'   , 'ches'
    rule 'sh'   , 'shes'
    rule 'ss'   , 'sses'
    rule 'ta'   , 'tum'
    rule 'ia'   , 'ium'
    rule 'ra'   , 'rum'
    rule 'ay'   , 'ays'
    rule 'ey'   , 'eys'
    rule 'oy'   , 'oys'
    rule 'uy'   , 'uys'
    rule 'y'    , 'ies'
    rule 'x'    , 'xes'
    rule 'lf'   , 'lves'
    rule 'us'   , 'uses'
    rule ''     , 's'

    # One-way singular rules.

    singular_rule 'of' , 'ofs' # proof
    singular_rule 'o'  , 'oes' # hero, heroes
    singular_rule 'f'  , 'ves'

    # One-way plural rules.

    plural_rule 'fe' , 'ves' # safe, wife
    plural_rule 's'  , 'ses'

  end
end
end

class String
  def singular
    Language::English::Inflect.singular(self)
  end
  alias_method(:singularize, :singular)
  def plural
    Language::English::Inflect.plural(self)
  end
  alias_method(:pluralize, :plural)
end