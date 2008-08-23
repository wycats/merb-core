module Merb  
  module Rack
    # Merb Rack application used by web server adapters.
    class Application
      # Called by web servser adapters. Must return 3 tuple of
      # status, Hash of headers and body that responds to :each and
      # yields strings (String, Proc or custom class instance).
      #
      # @param env<Hash>
      #   Rack environment
      #
      # @return Array(~to_s, Hash, ~each)
      def call(env) 
        begin
          controller = ::Merb::Dispatcher.handle(Merb::Request.new(env))
        rescue Object => e
          return [500, {Merb::Const::CONTENT_TYPE => "text/html"}, e.message + "<br/>" + e.backtrace.join("<br/>")]
        end
        Merb.logger.info "\n\n"
        Merb.logger.flush

        unless controller.headers[Merb::Const::DATE]
          require "time"
          controller.headers[Merb::Const::DATE] = Time.now.rfc2822.to_s
        end
        controller.rack_response
      end

      # Returns true for requests that should be deferred. Deferred requests
      # supposed to be served in threads to prevent event loop of event-driven
      # servers from blocking on long requests.
      #
      # Request is treated deferred if value of PATH_INFO matches regexp
      # returned by Merb.deferred_actions. See Merb.deferred_actions documentation.
      #
      # @note
      #   Thin and Ebb both support deferred requests.
      #
      # @param env<Hash>
      #   Rack environment.
      #
      # @return
      #   true if request is deferred
      def deferred?(env)
        path = env[Merb::Const::PATH_INFO] ? env[Merb::Const::PATH_INFO].chomp('/') : ""
        if path =~ Merb.deferred_actions
          Merb.logger.info! "Deferring Request: #{path}"
          true
        else
          false
        end        
      end # deferred?(env)
    end # Application
  end # Rack
end # Merb
