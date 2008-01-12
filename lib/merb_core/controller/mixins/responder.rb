require 'enumerator'
require 'merb_core/controller/mime'

module Merb
  # The ResponderMixin adds methods that help you manage what
  # formats your controllers have available, determine what format(s)
  # the client requested and is capable of handling, and perform
  # content negotiation to pick the proper content format to
  # deliver.
  # 
  # If you hear someone say "Use provides" they're talking about the
  # Responder.  If you hear someone ask "What happened to respond_to?"
  # it was replaced by provides and the other Responder methods.
  # 
  # == A simple example
  # 
  # The best way to understand how all of these pieces fit together is
  # with an example.  Here's a simple web-service ready resource that
  # provides a list of all the widgets we know about.  The widget list is 
  # available in 3 formats: :html (the default), plus :xml and :text.
  # 
  #     class Widgets < Application
  #       provides :html   # This is the default, but you can
  #                        # be explicit if you like.
  #       provides :xml, :text
  #       
  #       def index
  #         @widgets = Widget.fetch
  #         render @widgets
  #       end
  #     end
  # 
  # Let's look at some example requests for this list of widgets.  We'll
  # assume they're all GET requests, but that's only to make the examples
  # easier; this works for the full set of RESTful methods.
  # 
  # 1. The simplest case, /widgets.html
  #    Since the request includes a specific format (.html) we know
  #    what format to return.  Since :html is in our list of provided
  #    formats, that's what we'll return.  +render+ will look
  #    for an index.html.erb (or another template format
  #    like index.html.mab; see the documentation on Template engines)
  # 
  # 2. Almost as simple, /widgets.xml
  #    This is very similar.  They want :xml, we have :xml, so
  #    that's what they get.  If +render+ doesn't find an 
  #    index.xml.builder or similar template, it will call +to_xml+
  #    on @widgets.  This may or may not do something useful, but you can 
  #    see how it works.
  #
  # 3. A browser request for /widgets
  #    This time the URL doesn't say what format is being requested, so
  #    we'll look to the HTTP Accept: header.  If it's '*/*' (anything),
  #    we'll use the first format on our list, :html by default.
  #    
  #    If it parses to a list of accepted formats, we'll look through 
  #    them, in order, until we find one we have available.  If we find
  #    one, we'll use that.  Otherwise, we can't fulfill the request: 
  #    they asked for a format we don't have.  So we raise
  #    406: Not Acceptable.
  # 
  # == A more complex example
  # 
  # Sometimes you don't have the same code to handle each available 
  # format. Sometimes you need to load different data to serve
  # /widgets.xml versus /widgets.txt.  In that case, you can use
  # +content_type+ to determine what format will be delivered.
  # 
  #     class Widgets < Application
  #       def action1
  #         if content_type == :text
  #           Widget.load_text_formatted(params[:id])
  #         else
  #           render
  #         end
  #       end
  #       
  #       def action2
  #         case content_type
  #         when :html
  #           handle_html()
  #         when :xml
  #           handle_xml()
  #         when :text
  #           handle_text()
  #         else
  #           render
  #         end
  #       end
  #     end
  # 
  # You can do any standard Ruby flow control using +content_type+.  If
  # you don't call it yourself, it will be called (triggering content
  # negotiation) by +render+.
  #
  # Once +content_type+ has been called, the output format is frozen,
  # and none of the provides methods can be used.
  module ResponderMixin
    
    # ==== Parameters
    # base<Module>:: The module that ResponderMixin was mixed into
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.class_eval do
        class_inheritable_accessor :class_provided_formats
      end
      base.reset_provides
    end
    
    module ClassMethods
      
      # Adds symbols representing formats to the controller's
      # default list of provided_formats.  These will apply to
      # every action in the controller, unless modified in the action.
      # If the last argument is a Hash or an Array, these are regarded
      # as arguments to pass to the to_<mime_type> method as needed.
      #
      # ==== Parameters
      # *formats<Symbol>:: 
      #   A list of mime-types that the controller should provide
      def provides(*formats)
        formats.each do |fmt|
          self.class_provided_formats << fmt unless class_provided_formats.include?(fmt)
        end
      end
      
      def only_provides(*formats)
        clear_provides
        provides(*formats)
      end
      
      def does_not_provide(*formats)
        self.class_provided_formats -= formats
      end
      
      def clear_provides
        self.class_provided_formats.clear
      end
      
      def reset_provides
        only_provides(:html)
      end
      
      # Returns the current list of formats provided for this instance
      # of the controller.  It starts with what has been set in the controller
      # (or :html by default) but can be modifed on a per-action basis.      
      def _provided_formats
        @_provided_formats || class_provided_formats.dup
      end
      
      # Sets the provided formats for this action.  Usually, you would
      # use a combination of +provides+, +only_provides+ and +does_not_provide+
      # to manage this, but you can set it directly.
      # 
      # ==== Parameters
      # *formats<Symbol>:: A list of formats to be passed to provides
      def _set_provided_formats(*formats)
        _raise_if_content_type_already_set!
        @_provided_formats = []
        provides(*formats)
      end
      alias :_provided_formats= :_set_provided_formats   
      
      # Adds formats to the list of provided formats for this particular 
      # request. Usually used to add formats to a single action. See also
      # the controller-level provides that affects all actions in a controller.
      #
      # ==== Parameters
      # *formats<Symbol>:: A list of formats to add to the per-action list
      #                    of provided formats
      def provides(*formats)
        raise_if_content_type_already_set!
        formats.each do |fmt|
          self.provided_formats << fmt unless provided_formats.include?(fmt)
        end
      end

      # Sets list of provided formats for this particular 
      # request. Usually used to limit formats to a single action. See also
      # the controller-level only_provides that affects all actions
      # in a controller.      
      # 
      # ==== Parameters
      # *formats<Symbol>:: A list of formats to use as the per-action list
      #                    of provided formats
      def only_provides(*formats)
        self.set_provided_formats(*formats)
      end
      
      # Removes formats from the list of provided formats for this particular 
      # request. Usually used to remove formats from a single action.  See
      # also the controller-level does_not_provide that affects all actions in a
      # controller.
      def does_not_provide(*formats)
        formats.flatten!
        self.provided_formats -= formats
      end
      
      # Do the content negotiation:
      # 1. if params[:format] is there, and provided, use it
      # 2. Parse the Accept header
      # 3. If it's */*, use the first provided format
      # 4. Look for one that is provided, in order of request
      # 5. Raise 406 if none found
      def _perform_content_negotiation # :nodoc:
        raise Merb::ControllerExceptions::NotAcceptable if provided_formats.empty?
        if fmt = params[:format]
          return fmt.to_sym if provided_formats.include?(fmt.to_sym)
        else
          accepts = Responder.parse(request.accept).map {|t| t.to_sym}
          return provided_formats.first if accepts.include?(:all)
          return accepts.each { |type| break type if provided_formats.include?(type) }
        end
        raise Merb::ControllerExceptions::NotAcceptable          
      end      

      # Checks to see if content negotiation has already been performed.
      # If it has, you can no longer modify the list of provided formats.
      def _content_type_set?
        !@_content_type.nil?
      end

      # Returns the output format for this request, based on the 
      # provided formats, <tt>params[:format]</tt> and the client's HTTP
      # Accept header.
      #
      # The first time this is called, it triggers content negotiation
      # and caches the value.  Once you call +content_type+ you can
      # not set or change the list of provided formats.
      #
      # Called automatically by +render+, so you should only call it if
      # you need the value, not to trigger content negotiation. 
      def content_type
        unless _content_type_set?
          @_content_type = _perform_content_negotiation
          unless Merb.available_mime_types.has_key?(@_content_type)
            raise Merb::ControllerExceptions::NotAcceptable.new("Unknown content_type for response: #{@_content_type}") 
          end
          headers['Content-Type'] = Merb.available_mime_types[@_content_type].first
        end
        @_content_type
      end
      
    end
    
  end
    
end