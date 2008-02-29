class Object
  # Checks that an object has assigned an instance variable of name
  # :name
  # 
  # ===Example in a spec
  #  @my_obj.assigns(:my_value).should == @my_value
  def assigns(attr)
    self.instance_variable_get("@#{attr}")
  end
end
