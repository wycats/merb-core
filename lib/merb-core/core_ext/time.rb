class Time
  
  # @return <String>
  #   ISO 8601 compatible rendering of the Time object's properties.
  # 
  # @example
  #   Time.now.to_json # => "\"2008-03-28T17:54:20-05:00\""
  def to_json
    self.xmlschema.to_json
  end
  
end