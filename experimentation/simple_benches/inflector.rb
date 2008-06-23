

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
    word 'bass'

    # Two arguments defines a singular and plural exception.

    word 'Swiss'     , 'Swiss'
    word 'life'      , 'lives'
    word 'wife'      , 'wives'
    word 'virus'     , 'viri'
    word 'octopus'   , 'octopi'
    #word 'cactus'    , 'cacti'
    word 'goose'     , 'geese'
    word 'criterion' , 'criteria'
    word 'alias'     , 'aliases'
    word 'status'    , 'statuses'
    word 'axis'      , 'axes'
    word 'crisis'    , 'crises'
    word 'testis'    , 'testes'
    word 'child'     , 'children'
    word 'person'    , 'people'
    word 'quiz'      , 'quizes'
    word 'matrix'    , 'matrices'
    word 'vertex'    , 'vetices'
    word 'index'     , 'indices'
    word 'ox'        , 'oxen'
    word 'mouse'     , 'mice'
    word 'louse'     , 'lice'
    word 'thesis'    , 'theses'
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

  def english_singular
    Language::English::Inflect.singular(self)
  end

  def english_plural
    Language::English::Inflect.plural(self)
  end
end

require 'singleton'

# The Inflector transforms words from singular to plural, class names to table names, modularized class names to ones without,
# and class names to foreign keys. The default inflections for pluralization, singularization, and uncountable words are kept
# in inflections.rb.
module Inflector
  # A singleton instance of this class is yielded by Inflector.inflections, which can then be used to specify additional
  # inflection rules. Examples:
  #
  #   Inflector.inflections do |inflect|
  #     inflect.plural /^(ox)$/i, '\1\2en'
  #     inflect.singular /^(ox)en/i, '\1'
  #
  #     inflect.irregular 'octopus', 'octopi'
  #
  #     inflect.uncountable "equipment"
  #   end
  #
  # New rules are added at the top. So in the example above, the irregular rule for octopus will now be the first of the
  # pluralization and singularization rules that is runs. This guarantees that your rules run before any of the rules that may
  # already have been loaded.

  class Inflections
    include Singleton

    attr_reader :plurals, :singulars, :uncountables

    def initialize
      @plurals, @singulars, @uncountables = [], [], []
    end

    # Specifies a new pluralization rule and its replacement. The rule can either be a string or a regular expression.
    # The replacement should always be a string that may include references to the matched data from the rule.

    def plural(rule, replacement)
      @plurals.insert(0, [rule, replacement])
    end

    # Specifies a new singularization rule and its replacement. The rule can either be a string or a regular expression.
    # The replacement should always be a string that may include references to the matched data from the rule.

    def singular(rule, replacement)
      @singulars.insert(0, [rule, replacement])
    end

    # Specifies a new irregular that applies to both pluralization and singularization at the same time. This can only be used
    # for strings, not regular expressions. You simply pass the irregular in singular and plural form.
    #
    # Examples:
    #   irregular 'octopus', 'octopi'
    #   irregular 'person', 'people'

    def irregular(singular, plural)
      plural(Regexp.new("(#{singular[0,1]})#{singular[1..-1]}$", "i"), '\1' + plural[1..-1])
      singular(Regexp.new("(#{plural[0,1]})#{plural[1..-1]}$", "i"), '\1' + singular[1..-1])
    end

    # Add uncountable words that shouldn't be attempted inflected.
    #
    # Examples:
    #   uncountable "money"
    #   uncountable "money", "information"
    #   uncountable %w( money information rice )
    def uncountable(*words)
      (@uncountables << words).flatten!
    end

    # Clears the loaded inflections within a given scope (default is :all). Give the scope as a symbol of the inflection type,
    # the options are: :plurals, :singulars, :uncountables
    #
    # Examples:
    #   clear :all
    #   clear :plurals

    def clear(scope = :all)
      case scope
        when :all
          @plurals, @singulars, @uncountables = [], [], []
        else
          instance_variable_set "@#{scope}", []
      end
    end
  end

  extend self

  def inflections
    if block_given?
      yield Inflections.instance
    else
      Inflections.instance
    end
  end

  # Returns the plural form of the word in the string.
  #
  # Examples
  #   "post".pluralize #=> "posts"
  #   "octopus".pluralize #=> "octopi"
  #   "sheep".pluralize #=> "sheep"
  #   "words".pluralize #=> "words"
  #   "the blue mailman".pluralize #=> "the blue mailmen"
  #   "CamelOctopus".pluralize #=> "CamelOctopi"
  def pluralize(word)
    result = word.to_s.dup

    if inflections.uncountables.include?(result.downcase)
      result
    else
      inflections.plurals.each { |(rule, replacement)| break if result.gsub!(rule, replacement) }
      result
    end
  end

  # The reverse of pluralize, returns the singular form of a word in a string.
  #
  # Examples
  #   "posts".singularize #=> "post"
  #   "octopi".singularize #=> "octopus"
  #   "sheep".singluarize #=> "sheep"
  #   "word".singluarize #=> "word"
  #   "the blue mailmen".singularize #=> "the blue mailman"
  #   "CamelOctopi".singularize #=> "CamelOctopus"
  def singularize(word)
    result = word.to_s.dup

    if inflections.uncountables.include?(result.downcase)
      result
    else
      inflections.singulars.each { |(rule, replacement)| break if result.gsub!(rule, replacement) }
      result
    end
  end

  # By default, camelize converts strings to UpperCamelCase. If the argument to camelize
  # is set to ":lower" then camelize produces lowerCamelCase.
  #
  # camelize will also convert '/' to '::' which is useful for converting paths to namespaces
  #
  # Examples
  #   "active_record".camelize #=> "ActiveRecord"
  #   "active_record".camelize(:lower) #=> "activeRecord"
  #   "active_record/errors".camelize #=> "ActiveRecord::Errors"
  #   "active_record/errors".camelize(:lower) #=> "activeRecord::Errors"
  def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    else
      lower_case_and_underscored_word.first + camelize(lower_case_and_underscored_word)[1..-1]
    end
  end

  # Capitalizes all the words and replaces some characters in the string to create
  # a nicer looking title. Titleize is meant for creating pretty output. It is not
  # used in the Rails internals.
  #
  # titleize is also aliased as as titlecase
  #
  # Examples
  #   "man from the boondocks".titleize #=> "Man From The Boondocks"
  #   "x-men: the last stand".titleize #=> "X Men: The Last Stand"

  def titleize(word)
    humanize(underscore(word)).gsub(/\b([a-z])/) { $1.capitalize }
  end

  # The reverse of +camelize+. Makes an underscored form from the expression in the string.
  #
  # Changes '::' to '/' to convert namespaces to paths.
  #
  # Examples
  #   "ActiveRecord".underscore #=> "active_record"
  #   "ActiveRecord::Errors".underscore #=> active_record/errors

  def underscore(camel_cased_word)
    camel_cased_word.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end

  # Replaces underscores with dashes in the string.
  #
  # Example
  #   "puni_puni" #=> "puni-puni"

  def dasherize(underscored_word)
    underscored_word.gsub(/_/, '-')
  end

  # Capitalizes the first word and turns underscores into spaces and strips _id.
  # Like titleize, this is meant for creating pretty output.
  #
  # Examples
  #   "employee_salary" #=> "Employee salary"
  #   "author_id" #=> "Author"

  def humanize(lower_case_and_underscored_word)
    lower_case_and_underscored_word.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
  end

  # Removes the module part from the expression in the string
  #
  # Examples
  #   "ActiveRecord::CoreExtensions::String::Inflections".demodulize #=> "Inflections"
  #   "Inflections".demodulize #=> "Inflections"

  def demodulize(class_name_in_module)
    class_name_in_module.to_s.gsub(/^.*::/, '')
  end

  # Create the name of a table like Rails does for models to table names. This method
  # uses the pluralize method on the last word in the string.
  #
  # Examples
  #   "RawScaledScorer".tableize #=> "raw_scaled_scorers"
  #   "egg_and_ham".tableize #=> "egg_and_hams"
  #   "fancyCategory".tableize #=> "fancy_categories"
  def tableize(class_name)
    pluralize(underscore(class_name))
  end

  # Create a class name from a table name like Rails does for table names to models.
  # Note that this returns a string and not a Class. (To convert to an actual class
  # follow classify with constantize.)
  #
  # Examples
  #   "egg_and_hams".classify #=> "EggAndHam"
  #   "post".classify #=> "Post"

  def classify(table_name)
    # strip out any leading schema name
    camelize(singularize(table_name.to_s.sub(/.*\./, '')))
  end

  # Creates a foreign key name from a class name.
  # +separate_class_name_and_id_with_underscore+ sets whether
  # the method should put '_' between the name and 'id'.
  #
  # Examples
  #   "Message".foreign_key #=> "message_id"
  #   "Message".foreign_key(false) #=> "messageid"
  #   "Admin::Post".foreign_key #=> "post_id"
  def foreign_key(class_name, separate_class_name_and_id_with_underscore = true)
    underscore(demodulize(class_name)) + (separate_class_name_and_id_with_underscore ? "_id" : "id")
  end

  # Constantize tries to find a declared constant with the name specified
  # in the string. It raises a NameError when the name is not in CamelCase
  # or is not initialized.
  #
  # Examples
  #   "Module".constantize #=> Module
  #   "Class".constantize #=> Class

  def constantize(camel_cased_word)
    unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ camel_cased_word
      raise NameError, "#{camel_cased_word.inspect} is not a valid constant name!"
    end

    Object.module_eval("::#{$1}", __FILE__, __LINE__)
  end

  # Ordinalize turns a number into an ordinal string used to denote the
  # position in an ordered sequence such as 1st, 2nd, 3rd, 4th.
  #
  # Examples
  #   ordinalize(1)     # => "1st"
  #   ordinalize(2)     # => "2nd"
  #   ordinalize(1002)  # => "1002nd"
  #   ordinalize(1003)  # => "1003rd"
  def ordinalize(number)
    if (11..13).include?(number.to_i % 100)
      "#{number}th"
    else
      case number.to_i % 10
        when 1: "#{number}st"
        when 2: "#{number}nd"
        when 3: "#{number}rd"
        else    "#{number}th"
      end
    end
  end
end

Inflector.inflections do |inflect|
  inflect.plural(/$/, 's')
  inflect.plural(/s$/i, 's')
  inflect.plural(/(ax|test)is$/i, '\1es')
  inflect.plural(/(octop|vir)us$/i, '\1i')
  inflect.plural(/(alias|status)$/i, '\1es')
  inflect.plural(/(bu)s$/i, '\1ses')
  inflect.plural(/(buffal|tomat)o$/i, '\1oes')
  inflect.plural(/([ti])um$/i, '\1a')
  inflect.plural(/sis$/i, 'ses')
  inflect.plural(/(?:([^f])fe|([lr])f)$/i, '\1\2ves')
  inflect.plural(/(hive)$/i, '\1s')
  inflect.plural(/([^aeiouy]|qu)y$/i, '\1ies')
  inflect.plural(/(x|ch|ss|sh)$/i, '\1es')
  inflect.plural(/(matr|vert|ind)ix|ex$/i, '\1ices')
  inflect.plural(/([m|l])ouse$/i, '\1ice')
  inflect.plural(/^(ox)$/i, '\1en')
  inflect.plural(/(quiz)$/i, '\1zes')

  inflect.singular(/s$/i, '')
  inflect.singular(/(n)ews$/i, '\1ews')
  inflect.singular(/([ti])a$/i, '\1um')
  inflect.singular(/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$/i, '\1\2sis')
  inflect.singular(/(^analy)ses$/i, '\1sis')
  inflect.singular(/([^f])ves$/i, '\1fe')
  inflect.singular(/(hive)s$/i, '\1')
  inflect.singular(/(tive)s$/i, '\1')
  inflect.singular(/([lr])ves$/i, '\1f')
  inflect.singular(/([^aeiouy]|qu)ies$/i, '\1y')
  inflect.singular(/(s)eries$/i, '\1eries')
  inflect.singular(/(m)ovies$/i, '\1ovie')
  inflect.singular(/(x|ch|ss|sh)es$/i, '\1')
  inflect.singular(/([m|l])ice$/i, '\1ouse')
  inflect.singular(/(bus)es$/i, '\1')
  inflect.singular(/(o)es$/i, '\1')
  inflect.singular(/(shoe)s$/i, '\1')
  inflect.singular(/(cris|ax|test)es$/i, '\1is')
  inflect.singular(/(octop|vir)i$/i, '\1us')
  inflect.singular(/(alias|status)es$/i, '\1')
  inflect.singular(/^(ox)en/i, '\1')
  inflect.singular(/(vert|ind)ices$/i, '\1ex')
  inflect.singular(/(matr)ices$/i, '\1ix')
  inflect.singular(/(quiz)zes$/i, '\1')

  inflect.irregular('person', 'people')
  inflect.irregular('man', 'men')
  inflect.irregular('child', 'children')
  inflect.irregular('sex', 'sexes')
  inflect.irregular('move', 'moves')

  inflect.uncountable(%w(equipment information rice money species series fish sheep))
end

module Inflections

  def pluralize
    Inflector.pluralize(self)
  end

  def singularize
    Inflector.singularize(self)
  end

  def camelize(first_letter = :upper)
    case first_letter
      when :upper then Inflector.camelize(self, true)
      when :lower then Inflector.camelize(self, false)
    end
  end
  alias_method :camelcase, :camelize

  def titleize
    Inflector.titleize(self)
  end
  alias_method :titlecase, :titleize

  def underscore
    Inflector.underscore(self)
  end

  def dasherize
    Inflector.dasherize(self)
  end

  def demodulize
    Inflector.demodulize(self)
  end

  def tableize
    Inflector.tableize(self)
  end

  def classify
    Inflector.classify(self)
  end

  def humanize
    Inflector.humanize(self)
  end

  def foreign_key(separate_class_name_and_id_with_underscore = true)
    Inflector.foreign_key(self, separate_class_name_and_id_with_underscore)
  end

  def constantize
    Inflector.constantize(self)
  end
end

class String
  include Inflections
end

require 'benchmark'

TIMES = (ARGV[0] || 100_000).to_i

Benchmark.bmbm do |x|
  x.report("English boy => boys") do
    TIMES.times { "boy".english_plural }
  end
  
  x.report("Rails boy => boys") do
    TIMES.times { "boy".pluralize }
  end
  
  x.report("English boys => boy") do
    TIMES.times { "boys".english_singular }
  end
  
  x.report("Rails boy => boys") do
    TIMES.times { "boys".singularize }
  end  
  
  x.report("English wife => wives") do
    TIMES.times { "wife".english_plural }
  end
  
  x.report("Rails wife => wives") do
    TIMES.times { "wife".pluralize }
  end

  x.report("English wives => wife") do
    TIMES.times { "wives".english_singular }
  end
  
  x.report("Rails wives => wife") do
    TIMES.times { "wives".singularize }
  end
  
  x.report("English dwarf => dwarves") do
    TIMES.times { "dwarf".english_plural }
  end
  
  x.report("Rails dwarf => dwarves") do
    TIMES.times { "dwarf".pluralize }
  end
  
  x.report("English dwarves => dwarf") do
    TIMES.times { "dwarves".english_singular }
  end
  
  x.report("Rails dwarves => dwarf") do
    TIMES.times { "dwarves".singularize }
  end    
end

# TIMES = 100_000
#                                user     system      total        real
# English boy => boys        1.310000   0.000000   1.310000 (  1.332678)
# Rails boy => boys          2.830000   0.000000   2.830000 (  2.846847)
#
# English boys => boy        1.540000   0.010000   1.550000 (  1.576141)
# Rails boy => boys          3.140000   0.010000   3.150000 (  3.201089)
#
# English wife => wives      0.250000   0.010000   0.260000 (  0.261200)
# Rails wife => wives        2.150000   0.010000   2.160000 (  2.199219)
#
# English wives => wife      0.250000   0.000000   0.250000 (  0.264623)
# Rails wives => wife        3.130000   0.020000   3.150000 (  3.192153)
#
# English dwarf => dwarves   1.120000   0.000000   1.120000 (  1.159888)
# Rails dwarf => dwarves     2.150000   0.010000   2.160000 (  2.329601)
#
# English dwarves => dwarf   1.060000   0.010000   1.070000 (  1.338925)
# Rails dwarves => dwarf     2.900000   0.020000   2.920000 (  2.931470)