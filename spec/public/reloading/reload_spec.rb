require File.join(File.dirname(__FILE__), "spec_helper")

describe "The reloader" do
  
  def reload!
    Merb::BootLoader::ReloadClasses.reload
  end
  
  before :all do
    @reload_file = File.dirname(__FILE__) / "directory" / "app" / "controllers" / "reload.rb"
    File.open(@reload_file, "w") do |f|
      @text = <<-END
        class Reloader < Application
        end
        
        class Hello < Application
        end
      END
      f.puts @text
    end
    
    puts "  * Sleeping 500ms to wait for reloader"
    sleep 0.5
  end
  
  it "should reload files that were changed" do
    defined?(Hello).should_not be_nil
    defined?(Reloader).should_not be_nil
    defined?(Reloader2).should be_nil
    
    puts "  * Sleeping 500ms to wait for mtime to update to next second"    
    sleep 0.5
    
    File.open(@reload_file, "w") do |f|
      f.puts <<-END
        class Reloader < Application
        end
        
        class Reloader2
        end
      END
    end

    puts "  * Sleeping 500ms to wait for reloader"
    sleep 0.5
    
    defined?(Hello).should be_nil
    defined?(Reloader).should_not be_nil
    defined?(Reloader2).should_not be_nil
  end
  
  it "should remove classes for _abstract_subclasses" do
    File.open(@reload_file, "w") do |f|
      f.puts <<-END
        class Reloader < Application
        end
        
        class Reloader2 < Application
        end
      END
    end
    
    puts "  * Sleeping 500ms to wait for reloader"    
    sleep 0.5
    
    Merb::AbstractController._abstract_subclasses.should include("Reloader")
    Merb::AbstractController._abstract_subclasses.should include("Reloader2")    
    defined?(Hello).should be_nil
    defined?(Reloader).should_not be_nil
    defined?(Reloader2).should_not be_nil    
  end
  
  after :each do
    puts "  * Sleeping 500ms to wait for mtime to update to next second"    
    sleep 0.5
    File.open(@reload_file, "w") do |f|
      f.puts @text
    end
  end
end