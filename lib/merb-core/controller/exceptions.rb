# We need to guarantee that status_codes.rb loads first because
# we are going to borrow the StatusCodes from it.
require File.join(File.dirname(__FILE__), 'status_codes')

class Exception
  def action_name; self.class.action_name end
  
  def same?(other)
    self.class == other.class &&
    self.message == other.message &&
    self.backtrace == other.backtrace
  end
  
  def self.action_name
    if self == Exception
      return nil unless Object.const_defined?(:Exceptions) && 
        Exceptions.method_defined?(:exception)
    end
    name = self.to_s.split('::').last.snake_case
    Object.const_defined?(:Exceptions) && 
      Exceptions.method_defined?(name) ? name : superclass.action_name
  end
  
  def self.status; 500 end
end

module Merb
  
  # ControllerExceptions are a way of simplifying controller code by placing
  # exception logic back into the MVC pattern.
  #
  # When a ControllerException is raised within your application merb will
  # attempt to re-route the request to your Exceptions controller to render
  # the error in a friendly manor.
  #
  # For example you might have an action in your app that raises NotFound
  # if a resource was not available:
  #
  #   def show
  #     product = Product.find(params[:id])
  #     raise NotFound if product.nil?
  #     [...]
  #   end
  #
  # This would halt execution of your action and re-route it over to your
  # Exceptions controller which might look something like:
  #
  # class Exceptions < Application
  #   def not_found
  #     render :layout => :none
  #   end
  # end
  #
  # As usual, the not_found action will look for a template in
  #   app/views/exceptions/not_found.html.erb
  #
  # Note: All standard ControllerExceptions have an HTTP status code associated 
  # with them which is sent to the browser when the action is rendered.
  #
  # Note: If you do not specifiy how to handle raised ControllerExceptions 
  # or an unhandlable exception occurs within your customized exception action
  # then they will be rendered using the built-in error template.
  # In development mode this "built in" template will show stack-traces for
  # any of the ServerError family of exceptions (you can force the stack-trace
  # to display in production mode using the :exception_details config option
  # in merb.yml)
  #
  #
  # ==== Internal Exceptions 
  #
  # Any other rogue errors (not ControllerExceptions) that occur during the 
  # execution of your app will be converted into the ControllerException 
  # InternalServerError. And like all other exceptions, the
  # ControllerExceptions can be caught on your Exceptions controller.
  #
  # InternalServerErrors return status 500, a common use for customizing this
  # action might be to send emails to the development team, warning that their
  # application has exploded. Mock example:
  #
  #   def internal_server_error
  #     MySpecialMailer.deliver(
  #       "team@cowboys.com", 
  #       "Exception occured at #{Time.now}", 
  #       self.request.exceptions.first)
  #     render 'Something is wrong, but the team is on it!'
  #   end
  #
  # Note: The special method +exceptions+ is available on Merb::Request instances 
  # and contains the exceptions that was raised (this is handy if
  # you want to display the associated message or display more detailed info).
  #
  #
  # ==== Extending ControllerExceptions
  #
  # To extend the use of the ControllerExceptions one may extend any of the 
  # HTTPError classes.
  #
  # As an example we can create an exception called AdminAccessRequired.
  #
  #   class AdminAccessRequired < Merb::ControllerExceptions::Unauthorized; end
  #
  # Add the required action to our Exceptions controller
  #
  #   class Exceptions < Application
  #     def admin_access_required
  #       render
  #     end
  #   end
  #
  # In app/views/exceptions/admin_access_required.rhtml
  # 
  #   <h1>You're not an administrator!</h1>
  #   <p>You tried to access <%= @tried_to_access %> but that URL is 
  #   restricted to administrators.</p>
  #
  module ControllerExceptions
    
    # Mapping of status code names to their numeric value.
    STATUS_CODES = {}

    class Base < StandardError #:doc:

      # === Returns
      # Integer:: The status-code of the error.
      def status; self.class.status; end
      alias :to_i :status

      class << self
        alias :to_i :status
      end
    end

    Merb::StatusCodes::STATUS_CODES.each do |x|
      if x[:status]
        assign_constant = "STATUS_CODES[:#{x[:child_name].snake_case}] = #{x[:status]}"
        define_status_method = "def self.status; #{x[:status]} end"
      else
        assign_constant, define_status_method = "", ""
      end
      self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        #{assign_constant}
        class #{x[:child_name]} < #{x[:parent_name]}
          #{define_status_method}
        end
      RUBY
    end

  end
  
  # Required to show exceptions in the log file
  #
  # e<Exception>:: The exception that a message is being generated for
  def self.exception(e)
    "#{ e.message } - (#{ e.class })\n" <<  
    "#{(e.backtrace or []).join("\n")}" 
  end

end
