module ObjectSpace
  
  class << self

    # ==== Returns
    # Array:: All the classes in the object space.
    def classes
      klasses = []
      ObjectSpace.each_object(Class) {|o| klasses << o}
      klasses
    end
  end
  
end