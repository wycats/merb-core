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