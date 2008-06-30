require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

class MockTimedExecutor
  def self.every(seconds, &block)
    @@scheduled_action = block
  end
  def self.run_task
    @@scheduled_action.call 
  end
end

RealTimedExecutor = Merb::BootLoader::ReloadClasses::TimedExecutor
Merb::BootLoader::ReloadClasses::TimedExecutor = MockTimedExecutor

Merb.start :environment => 'test',
           :merb_root => File.dirname(__FILE__) / "directory"

describe "TimedExecutor" do
  it "should call a block of code repeatedly in the background" do
    list_of_things = []
    
    RealTimedExecutor.every(0.1) do
      list_of_things << "Something"
    end
    
    sleep 0.5
    
    list_of_things.should_not be_empty
    list_of_things.size.should > 1
  end
  
end

describe "The reloader" do

  before :all do
    @reload_file = File.dirname(__FILE__) / "directory" / "app" / "controllers" / "reload.rb"
    @text =  <<-END

        class Reloader < Application
        end

        class Hello < Application
        end
      END
     update_file @text
     MockTimedExecutor.run_task
  end

  def update_file(contents)
    mtime = File.mtime(@reload_file)
    f = File.open(@reload_file, "w") do |f|
      f.puts contents
    end
    File.utime(mtime+30, mtime+30, @reload_file)
  end

  it "should reload files that were changed" do
    defined?(Hello).should_not be_nil
    defined?(Reloader).should_not be_nil
    defined?(Reloader2).should be_nil

    update_file <<-END

        class Reloader < Application
        end

        class Reloader2
        end
      END
     
    MockTimedExecutor.run_task
    
    defined?(Hello).should be_nil
    defined?(Reloader).should_not be_nil
    defined?(Reloader2).should_not be_nil
  end

  it "should remove classes for _abstract_subclasses" do
    
    update_file <<-END

        class Reloader < Application
        end

        class Reloader2 < Application
        end
      END
    
    MockTimedExecutor.run_task

    Merb::AbstractController._abstract_subclasses.should include("Reloader")
    Merb::AbstractController._abstract_subclasses.should include("Reloader2")
    defined?(Hello).should be_nil
    defined?(Reloader).should_not be_nil
    defined?(Reloader2).should_not be_nil
  end

  after :each do
    update_file @text
    MockTimedExecutor.run_task
  end
end
