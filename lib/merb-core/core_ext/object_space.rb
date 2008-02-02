

# DOC: Yehuda Katz FAILED
module ObjectSpace
  
  class << self

    # DOC: Yehuda Katz FAILED
    def classes
      klasses = []
      ObjectSpace.each_object(Class) {|o| klasses << o}
      klasses
    end
  end
  
end