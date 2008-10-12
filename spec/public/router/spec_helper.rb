require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
require 'ostruct'
require 'rubygems'
gem "rspec"
require "spec"

module Spec
  module Matchers
    class HaveRoute
      def initialize(expected, exact = false)
        @expected = expected
        @exact = exact
      end

      def matches?(target)
        @target = target[1]
        @errors = []
        @expected.all? { |param, value| @target[param] == value } && (!@exact || @expected.length == @target.length)
      end

      def failure_message
        @target.each do |param, value|
          @errors << "Expected :#{param} to be #{@expected[param].inspect}, but was #{value.inspect}" unless
            @expected[param] == value
        end
        @errors << "Got #{@target.inspect}"
        @errors.join("\n")
      end

      def negative_failure_message
        "Expected #{@expected.inspect} not to be #{@target.inspect}, but it was."
      end

      def description() "have_route #{@target.inspect}" end
    end

    def have_route(expected)
      HaveRoute.new(expected)
    end
    
    def have_exact_route(expected)
      HaveRoute.new(expected, true)
    end
    
    class HaveRack
      def initialize(expected)
        @expected = expected
      end

      def matches?(rack)
        return false unless rack.last.is_a?(Array)
        @actual = Struct.new(:status, :headers, :body).new(rack.last[0], rack.last[1], rack.last[2])
        @expected.all? { |k, v| @actual[k] == v }
      end

      def failure_message
        "#{@actual.inspect} does not match #{@expected.inspect}"
      end

      def negative_failure_message
        "#{@actual.inspect} does match #{@expected.inspect}"
      end

      def description() "have_rack #{@actual.inspect}" end
    end
    
    def have_rack(expected)
      HaveRack.new(expected)
    end
    
    # class HaveNilRoute
    # 
    #   def matches?(target)
    #     @target = target
    #     target.last.empty?
    #   end
    # 
    #   def failure_message
    #     "Expected a nil route. Got #{@target.inspect}."
    #   end
    # 
    #   def negative_failure_message
    #     "Expected not to get a nil route."
    #   end
    # end
    # 
    def raise_not_found
      raise_error(Merb::ControllerExceptions::NotFound)
    end
  end
  
  module Helpers
    #
    # Creates a single route with the passed conditions and parameters without
    # registering it with Router
    # def route(conditions, params = {})
    #   conditions = {:path => conditions} unless Hash === conditions
    #   Merb::Router::Route.new(conditions, params)
    # end
    # 
    # #
    # # A shortcut for creating a single route and registering it with Router
    # def prepare_named_route(name, from, conditions = {}, to = nil)
    #   to, conditions = conditions, {} unless to
    #   Merb::Router.prepare {|r| r.match(from, conditions).to(to).name(name) }
    # end
    # 
    # def prepare_conditional_route(name, from, conditions, to = {})
    #   Merb::Router.prepare {|r| r.match(from, conditions).to(to).name(name) }
    # end
    # 
    def prepare_route(from = {}, to = {})
      name = :default
      Merb::Router.prepare {|r| r.match(from).to(to).name(name) }
    end
    
    def env_for(path, orig_env = {})
      env = orig_env.dup
      env["REQUEST_METHOD"]  = env.delete(:method).to_s if env[:method]
      env["HTTP_USER_AGENT"] = env.delete(:user_agent)  if env[:user_agent]
      env["HTTPS"]           = "on"                     if env.delete(:protocol) =~ /https/i
      env["REQUEST_PATH"]    = path
      
      if env[:host]
        env["HTTP_HOST"] = env.delete(:host)
      elsif env[:domain]
        env["HTTP_HOST"] = env.delete(:domain)
      end
      
      env
    end
    
    def simple_request(env = {})
      env_for("/", env)
    end

    #
    # Returns the dispatch parameters for a request by passing the request
    # through Router#match.
    def route_for(path, env = {}, &block)
      request = fake_request(env_for(path, env))
      yield request if block_given?
      Merb::Router.route_for(request)
    end
    
    def request_for(path, env = {}, &block)
      request = fake_request(env_for(path, env))
      yield request if block_given?
      Merb::Router.route_for(request)
      request
    end
    
    def matched_route_for(*args)
      route_for(*args).first
    end

  end
end

def it_should_be_a_resource_collection_route(name, *args)
  params = extract_options_from_args!(args) || {}
  prefix = args.first.is_a?(String) ? args.shift : ""
  opts   = args.first.is_a?(Hash)   ? args.shift : {}
  
  id = opts[:id] || "45"
  
  it "should provide #{name} with an 'index' route" do
    route_for("#{prefix}/#{name}").should          have_route({:action => "index", :controller => "#{name}",  :id => nil, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}/index").should    have_route({:action => "index", :controller => "#{name}",  :id => nil, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}.js").should       have_route({:action => "index", :controller => "#{name}",  :id => nil, :format => "js"}.merge(params))
    route_for("#{prefix}/#{name}/index.js").should have_route({:action => "index", :controller => "#{name}",  :id => nil, :format => "js"}.merge(params))
  end

  it "should provide #{name} with a 'new' route" do
    route_for("#{prefix}/#{name}/new").should    have_route({:action => "new", :controller => "#{name}", :id => nil, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}/new.js").should have_route({:action => "new", :controller => "#{name}", :id => nil, :format => "js"}.merge(params))
  end

  it "should provide #{name} with a 'create' route" do
    route_for("#{prefix}/#{name}",    :method => :post).should have_route({:action => "create", :controller => "#{name}", :id => nil, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}.js", :method => :post).should have_route({:action => "create", :controller => "#{name}", :id => nil, :format => "js"}.merge(params))
  end

  it "should provide #{name} with a 'show' route" do
    route_for("#{prefix}/#{name}/#{id}").should    have_route({:action => "show", :controller => "#{name}", :id => id, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}/#{id}.js").should have_route({:action => "show", :controller => "#{name}", :id => id, :format => "js"}.merge(params))
  end

  it "should provide #{name} with an 'edit' route" do
    route_for("#{prefix}/#{name}/#{id}/edit").should    have_route({:action => "edit", :controller => "#{name}", :id => id, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}/#{id}/edit.js").should have_route({:action => "edit", :controller => "#{name}", :id => id, :format => "js"}.merge(params))
  end

  it "should provide #{name} with an 'update' route" do
    route_for("#{prefix}/#{name}/#{id}",    :method => :put).should have_route({:action => "update", :controller => "#{name}", :id => id, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}/#{id}.js", :method => :put).should have_route({:action => "update", :controller => "#{name}", :id => id, :format => "js"}.merge(params))
  end

  it "should provide #{name} with a 'delete' route" do
    route_for("#{prefix}/#{name}/#{id}/delete").should    have_route({:action => "delete", :controller => "#{name}", :id => id, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}/#{id}/delete.js").should have_route({:action => "delete", :controller => "#{name}", :id => id, :format => "js"}.merge(params))
  end

  it "should provide #{name} with a 'destroy' route" do
    route_for("#{prefix}/#{name}/#{id}",    :method => :delete).should have_route({:action => "destroy", :controller => "#{name}", :id => id, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}/#{id}.js", :method => :delete).should have_route({:action => "destroy", :controller => "#{name}", :id => id, :format => "js"}.merge(params))
  end

  # --- I decided that all the routes here will have the following ---
  
  if !opts.has_key?(:extra) || opts[:extra]
    
    it "should provide #{name} with a 'one' collection route" do
      route_for("#{prefix}/#{name}/one").should    have_route({:action => "one", :controller => "#{name}", :format => nil }.merge(params))
      route_for("#{prefix}/#{name}/one.js").should have_route({:action => "one", :controller => "#{name}", :format => "js"}.merge(params))
    end

    it "should provide #{name} with a 'two' member route" do
      route_for("#{prefix}/#{name}/#{id}/two").should    have_route({:action => "two", :controller => "#{name}", :id => id, :format => nil }.merge(params))
      route_for("#{prefix}/#{name}/#{id}/two.js").should have_route({:action => "two", :controller => "#{name}", :id => id, :format => "js"}.merge(params))
    end

    it "should provide #{name} with a 'three' collection route that maps the 'awesome' method" do
      route_for("#{prefix}/#{name}/three").should    have_route({:action => "awesome", :controller => "#{name}", :format => nil }.merge(params))
      route_for("#{prefix}/#{name}/three.js").should have_route({:action => "awesome", :controller => "#{name}", :format => "js"}.merge(params))
    end

    it "should provide #{name} with a 'four' member route that maps to the 'awesome' method" do
      route_for("#{prefix}/#{name}/#{id}/four").should    have_route({:action => "awesome", :controller => "#{name}", :id => id, :format => nil }.merge(params))
      route_for("#{prefix}/#{name}/#{id}/four.js").should have_route({:action => "awesome", :controller => "#{name}", :id => id, :format => "js"}.merge(params))
    end
  end
end

def it_should_be_a_resource_object_route(name, *args)
  controller = "#{name}s"
  params     = extract_options_from_args!(args) || {}
  prefix     = args.first.is_a?(String) ? args.shift : ""
  opts       = args.first.is_a?(Hash)   ? args.shift : {}

  it "should provide #{name} with a 'show' route" do
    route_for("#{prefix}/#{name}").should    have_route({:action => "show", :controller => controller, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}.js").should have_route({:action => "show", :controller => controller, :format => "js"}.merge(params))
  end

  it "should provide #{name} with an 'edit' route" do
    route_for("#{prefix}/#{name}/edit").should    have_route({:action => "edit", :controller => controller, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}/edit.js").should have_route({:action => "edit", :controller => controller, :format => "js"}.merge(params))
  end

  it "should provide #{name} with an 'update' route" do
    route_for("#{prefix}/#{name}",    :method => :put).should have_route({:action => "update", :controller => controller, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}.js", :method => :put).should have_route({:action => "update", :controller => controller, :format => "js"}.merge(params))
  end

  it "should provide #{name} with a 'delete' route" do
    route_for("#{prefix}/#{name}/delete").should    have_route({:action => "delete", :controller => controller, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}/delete.js").should have_route({:action => "delete", :controller => controller, :format => "js"}.merge(params))
  end

  it "should provide #{name} with a 'destroy' route" do
    route_for("#{prefix}/#{name}",    :method => :delete).should have_route({:action => "destroy", :controller => controller, :format => nil}.merge(params))
    route_for("#{prefix}/#{name}.js", :method => :delete).should have_route({:action => "destroy", :controller => controller, :format => "js"}.merge(params))
  end

  it "should provide #{name} with a 'one' member route" do
    route_for("#{prefix}/#{name}/one").should    have_route({:action => "one", :controller => controller, :format => nil}.merge(params))
    route_for("#{prefix}/#{name}/one.js").should have_route({:action => "one", :controller => controller, :format => "js"}.merge(params))
  end

  it "should provide #{name} with a 'two' member route that maps to the 'awesome' method" do
    route_for("#{prefix}/#{name}/two").should    have_route({:action => "awesome", :controller => controller, :format => nil }.merge(params))
    route_for("#{prefix}/#{name}/two.js").should have_route({:action => "awesome", :controller => controller, :format => "js"}.merge(params))
  end
end

Spec::Runner.configure do |config|
  config.include(Spec::Helpers)
  config.include(Spec::Matchers)
  config.before(:each) do
    @_root_behavior = Merb::Router.root_behavior
  end
  config.after(:each) do
    Merb::Router.root_behavior = @_root_behavior
    Merb::Router.reset!
  end
end