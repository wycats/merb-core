require "rubygems"
require "rbench"

require "activesupport"

class StringQuestioneer < String
  def method_missing(method_name, *arguments)
    if method_name.to_s.ends_with?("?")
      self == method_name.to_s[0..-2]
    else
      super
    end
  end
end

class ImprovedQuestioneer < String
 def method_missing(method_name, *arguments)
   if method_name.to_s =~ /(.*)\?$/
     self == $1
   else
     super
   end
 end
end

class AwesomeQuestioneer < String
  def initialize(str)
    class << self; self; end.class_eval <<-RUBY
      def #{str}?
        true
      end
    RUBY
  end
  
  def method_missing(meth, *args)
    meth.to_s[-1] == ?? ? false : super
  end
end

S_QUESTIONEER = StringQuestioneer.new("awesome")
I_QUESTIONEER = ImprovedQuestioneer.new("awesome")
B_QUESTIONEER = AwesomeQuestioneer.new("awesome")
AWESOME = "awesome"

RBench.run(100_000) do
  group "true" do
    report "questioneer" do
      I_QUESTIONEER.awesome?
    end

    report "improved_questioneer" do
      I_QUESTIONEER.awesome?
    end
  
    report "awesome_questioneer" do
      B_QUESTIONEER.awesome?
    end
  
    report "==" do
      AWESOME == "awesome"
    end
  end
  
  group "false" do
    report "questioneer" do
      I_QUESTIONEER.not_awesome?
    end

    report "improved_questioneer" do
      I_QUESTIONEER.not_awesome?
    end
  
    report "awesome_questioneer" do
      B_QUESTIONEER.not_awesome?
    end
  
    report "==" do
      AWESOME == "not_awesome"
    end    
  end
end

#                              Results |
# --true--------------------------------
# questioneer                    0.480 |
# improved_questioneer           0.465 |
# awesome_questioneer            0.028 |
# ==                             0.105 |
# --false-------------------------------
# questioneer                    0.466 |
# improved_questioneer           0.465 |
# awesome_questioneer            0.284 |
# ==                             0.098 |
