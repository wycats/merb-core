class Foo < Application
   
  def index
    session[:foo] = Time.now
    "hello!"
  end
  
  def hello
    puts session[:foo]
    render
  end  

end  