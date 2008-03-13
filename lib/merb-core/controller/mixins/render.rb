module Merb::RenderMixin
  # So we can do raise TemplateNotFound
  include Merb::ControllerExceptions
  
  # ==== Parameters
  # base<Module>:: Module that is including RenderMixin (probably a controller)
  def self.included(base)
    base.class_eval do
      class_inheritable_accessor :_layout, :_cached_templates
    end
  end
  
  # Render the specified item, with the specified options.
  #
  # ==== Parameters
  # thing<String, Symbol, nil>:: 
  #   The thing to render. This will default to the current action
  # opts<Hash>:: An options hash (see below)
  #
  # ==== Options (opts)
  # :format<Symbol>:: A registered mime-type format
  # :template<String>:: 
  #   The path to the template relative to the template root
  # :status<~to_i>:: 
  #   The status to send to the client. Typically, this would be an integer
  #   (200), or a Merb status code (Accepted)
  # :layout<~to_s>::
  #   A layout to use instead of the default. This should be relative to the
  #   layout root. By default, the layout will be either the controller_name or
  #   application. If you want to use an alternative content-type than the one
  #   that the base template was rendered as, you will need to do :layout =>
  #   "foo.#{content_type}" (i.e. "foo.json")
  #
  # ==== Returns
  # String:: The rendered template, including layout, if appropriate.
  #
  # ==== Raises
  # TemplateNotFound:: There is no template for the specified location.
  # 
  # ==== Alternatives
  # If you pass a Hash as the first parameter, it will be moved to opts and
  # "thing" will be the current action
  #---
  # @public
  def render(thing = nil, opts = {})
    # render :format => :xml means render nil, :format => :xml
    opts, thing = thing, nil if thing.is_a?(Hash)
    
    # If you don't specify a thing to render, assume they want to render the current action
    thing ||= action_name.to_sym

    # Content negotiation
    opts[:format] ? (self.content_type = opts[:format]) : content_type 
    
    # Handle options (:status)
    _handle_options!(opts)    
    
    # Do we have a template to try to render?
    if thing.is_a?(Symbol) || opts[:template]

      template_method, template_location = _template_for(thing, content_type, controller_name, opts)
  
      # Raise an error if there's no template
      raise TemplateNotFound, "No template found at #{template_location}.*"  \
        unless template_method && self.respond_to?(template_method)

      # Call the method in question and throw the content for later consumption by the layout
      throw_content(:for_layout, self.send(template_method))
      
    # Do we have a string to render?
    elsif thing.is_a?(String)
      
      # Throw it for later consumption by the layout
      throw_content(:for_layout, thing)
    end
    
    # If we find a layout, use it. Otherwise, just render the content thrown for layout.
    layout = opts[:layout] != false && _get_layout(opts[:layout])
    layout ? send(layout) : catch_content(:for_layout)
  end
    
  # Renders an object using to registered transform method based on the
  # negotiated content-type, if a template does not exist. For instance, if the
  # content-type is :json, Merb will first look for current_action.json.*.
  # Failing that, it will run object.to_json.
  #
  # ==== Parameter
  # object<Object>:: 
  #   An object that responds_to? the transform method registered for the
  #   negotiated mime-type.
  # thing<String, Symbol>::
  #   The thing to attempt to render via #render before calling the transform
  #   method on the object. Defaults to nil.
  # opts<Hash>:: An options hash that will be passed on to #render
  # 
  # ==== Returns
  # String::
  #   The rendered template or if no template is found, the transformed object.
  #
  # ==== Raises
  # NotAcceptable::
  #   If there is no transform method for the specified mime-type or the object
  #   does not respond to the transform method.
  # 
  # ==== Alternatives
  # A string in the second parameter will be interpreted as a template:
  #   display @object, "path/to/foo" 
  #   #=> display @object, nil, :template => "path/to/foo"
  #
  # A hash in the second parameters will be interpreted as opts:
  #   display @object, :layout => "zoo"
  #   #=> display @object, nil, :layout => "zoo"
  #
  # ==== Note
  # The transformed object will not be used in a layout unless a :layout is
  # explicitly passed in the opts.
  def display(object, thing = nil, opts = {})
    # display @object, "path/to/foo" means display @object, nil, :template => "path/to/foo"
    # display @object, :template => "path/to/foo" means display @object, nil, :template => "path/to/foo"
    opts[:template], thing = thing, nil if thing.is_a?(String) || thing.is_a?(Hash)
    
    # Try to render without the object
    render(thing || action_name.to_sym, opts)
  
  # If the render fails (i.e. a template was not found)
  rescue TemplateNotFound
    
    # Figure out what to transform and raise NotAcceptable unless there's a transform method assigned
    transform = Merb.mime_transform_method(content_type)
    raise NotAcceptable unless transform && object.respond_to?(transform)
    
    # Throw the transformed object for later consumption by the layout
    throw_content(:for_layout, object.send(transform))
  
    # Only use a layout if one was specified
    if opts[:layout]
      # Look for the layout under the default layout directly. If it's not found, reraise
      # the TemplateNotFound error
      template = _template_location(opts[:layout], layout.index(".") ? content_type : nil, "layout")      
      layout = _template_for(_template_root / template) ||
        (raise TemplateNotFound, "No layout found at #{_template_root / template}.*")      
              
      # If the layout was found, call it
      send(layout)
    
    # Otherwise, just render the transformed object
    else
      catch_content(:for_layout)
    end
  end

  # Render a partial template.
  #
  # ==== Parameters
  # template<~to_s>::
  #   The path to the template, relative to the current controller or the 
  #   template root. If the template contains a "/", Merb will search for it
  #   relative to the template root; otherwise, Merb will search for it
  #   relative to the current controller.
  # opts<Hash>:: A hash of options (see below)
  #
  # ==== Options (opts)
  # :with<Object, Array>::
  #   An object or an array of objects that will be passed into the partial.
  # :as<~to_sym>:: The local name of the :with Object inside of the partial.
  # :format<Symbol>:: The mime format that you want the partial to be in (:js, :html, etc.)
  # others::
  #   A Hash object names and values that will be the local names and values
  #   inside the partial.
  #
  # ==== Example
  #   partial :foo, :hello => @object
  #
  # The "_foo" partial will be called, relative to the current controller,
  # with a local variable of +hello+ inside of it, assigned to @object.
  def partial(template, opts={})

    # partial :foo becomes "#{controller_name}/_foo"
    # partial "foo/bar" becomes "foo/_bar"
    template = template.to_s
    kontroller = (m = template.match(/.*(?=\/)/)) ? m[0] : controller_name
    template = "_#{File.basename(template)}"
    
    template_method, template_location = _template_for(template, opts.delete(:format) || content_type, kontroller)

    (@_old_partial_locals ||= []).push @_merb_partial_locals

    if opts.key?(:with)
      with = opts.delete(:with)
      as = opts.delete(:as) || template_location.match(%r[.*/_([^\.]*)])[1]
      @_merb_partial_locals = opts
      sent_template = [with].flatten.map do |temp|
        @_merb_partial_locals[as.to_sym] = temp
        send(template_method)
      end.join
    else
      @_merb_partial_locals = opts
      sent_template = send(template_method)
    end
    @_merb_partial_locals = @_old_partial_locals.pop
    sent_template
  end      
  
  # Take the options hash and handle it as appropriate.
  # 
  # ==== Parameters
  # opts<Hash>:: The options hash that was passed into render.
  # 
  # ==== Options
  # :status<~to_i>::
  #   The status of the response will be set to opts[:status].to_i
  # 
  # ==== Returns
  # Hash:: The options hash that was passed in.
  def _handle_options!(opts)
    self.status = opts[:status].to_i if opts[:status]
    opts
  end

  # Get the layout that should be used. The content-type will be appended to
  # the layout unless the layout already contains a "." in it.
  #
  # If no layout was passed in, this method will look for one with the same
  # name as the controller, and finally one in "application.#{content_type}".
  #
  # ==== Parameters
  # layout<~to_s>:: A layout, relative to the layout root. Defaults to nil.
  # 
  # ==== Returns
  # String:: The method name that corresponds to the found layout.
  # 
  # ==== Raises
  # TemplateNotFound::
  #   If a layout was specified (either via layout in the class or by passing
  #   one in to this method), and not found. No error will be raised if no
  #   layout was specified, and the default layouts were not found.
  def _get_layout(layout = nil)
    if _layout && !layout
      layout = _layout.instance_of?(Symbol) && self.respond_to?(_layout, true) ? send(_layout) : _layout
    end
    layout = layout.to_s if layout
    
    # If a layout was provided, throw an error if it's not found
    if layout
      template_method, template_location = _template_for(layout, layout.index(".") ? nil : content_type, "layout")
      raise TemplateNotFound, "No layout found at #{template_location}" unless template_method
      template_method

    # If a layout was not provided, try the default locations
    else
      template, location = _template_for(controller_name, content_type, "layout")
      template, location = _template_for("application", content_type, "layout") unless template
      template
    end
  end
  
  # Iterate over the template roots in reverse order, and return the template 
  # and template location of the first match.
  #
  # ==== Parameters
  # thing<Object>:: The controller action.
  # content_type<~to_s>:: The content type. Defaults to nil.
  # controller<~to_s>:: The name of the controller. Defaults to nil.
  #
  # ==== Options (opts)
  # :template<String>::
  #   The location of the template to use. Defaults to whatever matches this
  #   thing, content_type and controller.
  #
  # ==== Returns
  # Array[Symbol, String]::
  #   A pair consisting of the template method and location.
  def _template_for(thing, content_type, controller=nil, opts={})
    template_method = nil
    template_location = nil
    
    self.class._template_roots.reverse_each do |root, template_location| 
      template_location = root / (opts[:template] || self.send(template_location, thing, content_type, controller))
      template_method = Merb::Template.template_for(template_location)
      break if template_method && self.respond_to?(template_method)
    end

    [template_method, template_location]
  end
    
  # Called in templates to get at content thrown in another template. The
  # results of rendering a template are automatically thrown into :for_layout,
  # so catch_content or catch_content(:for_layout) can be used inside layouts
  # to get the content rendered by the action template.
  #
  # ==== Parameters
  # obj<Object>:: The key in the thrown_content hash. Defaults to :for_layout.
  #---
  # @public
  def catch_content(obj = :for_layout)
    @_caught_content[obj]
  end
  
  # Called in templates to store up content for later use. Takes a string
  # and/or a block. First, the string is evaluated, and then the block is
  # captured using the capture() helper provided by the template languages. The
  # two are concatenated together.
  #
  # ==== Parameters
  # obj<Object>:: The key in the thrown_content hash.
  # string<String>:: Textual content. Defaults to nil.
  # &block:: A block to be evaluated and concatenated to string.
  #
  # ==== Raises
  # ArgumentError:: Neither string nor block given.
  #
  # ==== Example
  #   throw_content(:foo, "Foo")
  #   catch_content(:foo) #=> "Foo"
  #---
  # @public
  def throw_content(obj, string = nil, &block)
    unless string || block_given?
      raise ArgumentError, "You must pass a block or a string into throw_content"
    end
    @_caught_content[obj] = string.to_s << (block_given? ? capture(&block) : "")
  end
  
end
