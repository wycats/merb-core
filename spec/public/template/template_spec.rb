# ==== Public Template API
# Merb::Template.register_extensions(engine<Class>, extenstions<Array[String]>)
#
# ==== Semipublic Template API
# Merb::Template.engine_for(path<String>)
# Merb::Template.template_name(path<String>)
# Merb::Template.inline_template(path<String>, mod<Module>)
#
# ==== Requirements for a new Template Engine
# A Template Engine must have at least a single class method called compile_template
# with the following parameters:
# * path<String>:: the full path to the template being compiled
# * name<String>:: the name of the method that will be inlined
# * mod<Module>:: the module that the method will be inlined into
require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

# A small structure to hold the templates so we can test the templating system in isolation
# from the framework

module Merb::Test::Fixtures
  # This is a fake templating engine that just copies the text of the template
  # exactly from the file
  
  class MyTemplateEngine
    
    def self.compile_template(io, name, mod)
      text = io.read
      table = { "\r"=>"\\r", "\n"=>"\\n", "\t"=>"\\t", '"'=>'\\"', "\\"=>"\\\\" }      
      text = (text.split("\n").map {|x| '"' + (x.gsub(/[\r\n\t"\\]/) { |m| table[m] }) + '"'}).join(" +\n")
      mod.class_eval <<-EOS, File.expand_path(io.path)
        def #{name}
          #{text}
        end
      EOS
    end
    
    module Mixin
    end
  end

  module MyHelpers
  end

  class Environment
    include MyHelpers
  end
end

describe Merb::Template do
  
  # @public
  it "should accept template-type registrations via #register_extensions" do
    Merb::Template.register_extensions(Merb::Test::Fixtures::MyTemplateEngine, %w[myt])
    Merb::Template.engine_for("foo.myt").should == Merb::Test::Fixtures::MyTemplateEngine
    Merb::Template.template_extensions.should include("myt")
  end
  
  # @semipublic
  
  def rendering_template(template_path)
    Merb::Template.inline_template(File.open(template_path), Merb::Test::Fixtures::MyHelpers)
    Merb::Test::Fixtures::Environment.new.
      send(Merb::Template.template_name(template_path))  
  end
  alias_method :render_template, :rendering_template
  
  it "should compile and inline templates via #inline methods for custom languages" do
    template_path = File.dirname(__FILE__) / "templates" / "template.html.myt"
    rendering_template(template_path).should == "Hello world!"
  end
  
  it "should compile and inline templates via #inline_template for erubis" do
    template_path = File.dirname(__FILE__) / "templates" / "template.html.erb"
    rendering_template(template_path).should == "Hello world!"
  end
  
  it "should compile and inline templates that comes through via VirtualFile" do
    Merb::Template.inline_template(VirtualFile.new("Hello", 
      File.dirname(__FILE__) / "templates" / "template.html.erb"), 
      Merb::Test::Fixtures::MyHelpers)
      
    res = Merb::Test::Fixtures::Environment.new.
      send(Merb::Template.template_name(File.dirname(__FILE__) / "templates" / "template.html.erb"))
      
    res.should == "Hello"
  end
  
  it "should know how to correctly report errors" do
    template_path = File.dirname(__FILE__) / "templates" / "error.html.erb"
    running { render_template(template_path) }.should raise_error(NameError, /`foo'/)
    begin
      render_template(template_path)
    rescue Exception => e
      e.backtrace.first.match(/\/([^:\/]*:\d*)/)[1].should == "error.html.erb:2"
    end
  end
  
  it "should find the full template name for a path via #template_for" do
    template_path = File.dirname(__FILE__) / "templates" / "template.html.erb"
    name = Merb::Template.inline_template(File.open(template_path), Merb::Test::Fixtures::MyHelpers)
    Merb::Test::Fixtures::Environment.new.should respond_to(name)
  end
  
end