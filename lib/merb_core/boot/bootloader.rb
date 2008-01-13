module Merb
  
  def self.start
    BootLoader.run
  end
  
  class BootLoader
    
    cattr_accessor :_subclasses
    class_inheritable_accessor :_after, :_before
    
    class << self
      
      def inherited(klass)
        unless klass._before || klass._after
          _subclasses << klass.to_s
        elsif klass._before
          _subclasses.insert(_subclasses.index(klass._before), klass)
        else
          _subclasses.insert(_subclasses.index(klass._before) + 1, klass)          
        end
        super
      end
      
      def run
        _subclasses.each {|klass| klass.new.run! }
      end
      
      def after(klass)
        _after = klass
      end
      
      def before(klass)
        _before = klass
      end
      
    end
    
  end
  
end

class Merb::BootLoader::BuildFramework < Merb::BootLoader
  def run
    build_framework
  end
  
  # This method should be overridden in merb_init.rb before Merb.start to set up a different
  # framework structure
  def build_framework
    %[view model controller helper mailer part].each do |component|
      Merb.push_path(component.to_sym, Merb.root_path "app/#{component}s")
    end
    Merb.push_path(:app_controller, Merb.root_path "app/controllers", "application_controller.rb")
    Merb.push_path(:config,         Merb.root_path "config", "router.rb")
    Merb.push_path(:lib,            Merb.root_path "lib")    
  end
end

class Merb::BootLoader::LoadPaths < Merb::BootLoader
  def run
    # Add models, controllers, and lib to the load path
    $LOAD_PATH.unshift Merb.load_paths[:model].first      if Merb.load_paths[:model]
    $LOAD_PATH.unshift Merb.load_paths[:controller].first if Merb.load_paths[:controller]
    $LOAD_PATH.unshift Merb.load_paths[:lib].first        if Merb.load_paths[:lib]
    
    # Require all the files in the registered load paths
    Merb.load_paths.each do |name, path|
      Dir[path.first / path.last].each {|f| require f}
    end
  end
end