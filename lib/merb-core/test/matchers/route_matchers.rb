module Merb::Test::Rspec::RouteMatchers
  
  class RouteToMatcher
    def initialize(klass_or_name, action)
      @expected_controller = Class === klass_or_name ? klass_or_name.name : klass_or_name
      @expected_action = action.to_s
    end
  
    def matches?(target)
      @target_env = target.dup
      @target_controller, @target_action = @target_env.delete(:controller).to_s, @target_env.delete(:action).to_s
      
      @target_controller = "#{target.delete(:namespace)}::#{@target_controller}" if target.has_key?(:namespace)
      
      @expected_controller.snake_case == @target_controller.snake_case && @expected_action == @target_action && match_parameters(@target_env)
    end
  
    def match_parameters(target)
      @parameter_matcher.nil? ? true : @parameter_matcher.matches?(target)
    end
  
    def with(parameters)
      @paramter_matcher = ParameterMatcher.new(parameters)
      
      self
    end
  
    def failure_message
      "expected the request to route to #{camelize(@expected_controller)}##{@expected_action}, but was #{camelize(@target_controller)}##{@target_action}"
    end
  
    def negative_failure_message
      "expected the request not to route to #{camelize(@expected_controller)}##{@expected_action}, but it did"
    end
    
    def camelize(word)
      word.to_s.gsub(/^[a-z]|(\_[a-z])/) { |a| a.upcase.gsub("_", "") }
    end
  end

  class ParameterMatcher
    def initialize(hash_or_object)
      @expected = {}
      case hash_or_object
      when Hash then @expected = hash_or_object
      else @expected[:id] = hash_or_object.to_param
      end
    end
  
    def matches?(parameter_hash)
      @actual = parameter_hash.dup.except(:controller, :action)
    
      @expected.all? {|(k, v)| @actual.has_key?(k) && @actual[k] == v}
    end
  
    def failure_message
      "expected the route to contain parameters #{@expected.inspect}, but instead contained #{@actual.inspect}"
    end
  
    def negative_failure_message
      "expected the route not to contain parameters #{@expected.inspect}, but it did"
    end
  end
  
  # Passes when the actual route parameters match the expected controller class and
  # controller action.  Exposes a +with+ method for specifying parameters.
  #
  # ==== Paramters
  # klass_or_name<Class, String>::
  #   The type or type name of the expected controller.
  # action<Symbol, String>:: Method name of the action.  Works with strings or symbols.
  # ==== Example
  #   # Passes if a GET request to "/" is routed to the Widgets controller's index action.
  #   request_to("/", :get).should route_to(Widgets, :index)
  #
  #   # Use the 'with' method for parameter checks
  #   request_to("/123").should route_to(widgets, :show).with(:id => "123")
  #
  def route_to(klass_or_name, action)
    RouteToMatcher.new(klass_or_name, action)
  end
end