class Hash
  def extract!(*args)
    args.map do |arg|
      self.delete(arg)
    end
  end
end