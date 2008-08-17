module Merb
  # This module is mixed into all of the implemented controllers.
  module ControllerMixin
    
    # Enqueue a block to run in a background thread outside of the request
    # response dispatch.
    #
    # @example
    #   run_later do
    #     SomeBackgroundTask.run
    #   end
    #
    # @param &block
    #   The block to run later.
    def run_later(&blk)
      Merb::Dispatcher.work_queue << blk
    end
    
    # Renders the block given as a parameter using chunked encoding.
    #
    # @example
    #   def stream
    #     prefix = '<p>'
    #     suffix = "</p>\r\n"
    #     render_chunked do
    #       IO.popen("cat /tmp/test.log") do |io|
    #         done = false
    #         until done
    #           sleep 0.3
    #           line = io.gets.chomp
    #           
    #           if line == 'EOF'
    #             done = true
    #           else
    #             send_chunk(prefix + line + suffix)
    #           end
    #         end
    #       end
    #     end
    #   end
    #
    # @param &blk
    #   A block that, when called, will use send_chunks to send chunks of data
    #   down to the server. The chunking will terminate once the block returns.
    def render_chunked(&blk)
      must_support_streaming!
      headers['Transfer-Encoding'] = 'chunked'
      Proc.new { |response|
        @response = response
        response.send_status_no_connection_close('')
        response.send_header
        blk.call
        response.write("0\r\n\r\n")
      }
    end

    # Writes a chunk from +render_chunked+ to the response that is sent back to
    # the client. This should only be called within a +render_chunked+ block.
    #
    # @param [String] data
    #   A chunk of data to return.
    def send_chunk(data)
      @response.write('%x' % data.size + "\r\n")
      @response.write(data + "\r\n")
    end
    
    # @param &blk
    #   A proc that should get called outside the mutex, and which will return
    #   the value to render.
    #
    # @return [Proc]
    #   A block that Mongrel can call later, allowing Merb to release the
    #   thread lock and render another request.
    def render_deferred(&blk)
      must_support_streaming!
      Proc.new {|response|
        result = blk.call
        response.send_status(result.length)
        response.send_header
        response.write(result)
      }
    end
    
    # Renders the passed in string, then calls the block outside the mutex and
    # after the string has been returned to the client.
    #
    # @param [String] str
    #   A +String+ to return to the client.
    # @param &blk
    #   A block that should get called once the string has been returned.
    #
    # @return [Proc] 
    #   A block that Mongrel can call after returning the string to the user.
    def render_then_call(str, &blk)
      must_support_streaming!
      Proc.new {|response|
        response.send_status(str.length)
        response.send_header
        response.write(str)
        blk.call        
      }      
    end

    # Sends a redirect to a url, optionally with a query string message and/or
    # a permanent move status code.
    #
    # @example
    #   redirect("/posts/34")
    #   redirect("/posts/34", :message => { :notice => 'Post updated successfully!' })
    #   redirect("http://www.merbivore.com/")
    #   redirect("http://www.merbivore.com/", :permanent => true)
    #
    # @param [String] url
    #   URL to redirect to. It can be either a relative or fully-qualified URL.
    #
    # @option :message [Hash]
    #   Messages to pass in url query string as value for "_message"
    # @option :permanent [Boolean]
    #   When true, return status 301 Moved Permanently
    #
    # @return [String]
    #   Explanation of redirect.
    def redirect(url, opts = {})
      default_redirect_options = { :message => nil, :permanent => false }
      opts = default_redirect_options.merge(opts)
      if opts[:message]
        notice = Merb::Request.escape([Marshal.dump(opts[:message])].pack("m"))
        url = url =~ /\?/ ? "#{url}&_message=#{notice}" : "#{url}?_message=#{notice}"
      end
      self.status = opts[:permanent] ? 301 : 302
      Merb.logger.info("Redirecting to: #{url} (#{self.status})")
      headers['Location'] = url
      "<html><body>You are being <a href=\"#{url}\">redirected</a>.</body></html>"
    end
    
    def message
      @_message = defined?(@_message) ? @_message : request.message
    end
    
    # Sends a file over HTTP.  When given a path to a file, it will set the
    # right headers so that the static file is served directly.
    #
    # @param [String] file
    #   Path to file to send to the client.
    #
    # @option :disposition [String]
    #   The disposition of the file send. Defaults to "attachment".
    # @option :filename [String]
    #   The name to use for the file. Defaults to the filename of file.
    # @option :type [String]
    #   The content type.
    #
    # @return
    #   IO:: An I/O stream for the file.
    def send_file(file, opts={})
      opts.update(Merb::Const::DEFAULT_SEND_FILE_OPTIONS.merge(opts))
      disposition = opts[:disposition].dup || 'attachment'
      disposition << %(; filename="#{opts[:filename] ? opts[:filename] : File.basename(file)}")
      headers.update(
        'Content-Type'              => opts[:type].strip,  # fixes a problem with extra '\r' with some browsers
        'Content-Disposition'       => disposition,
        'Content-Transfer-Encoding' => 'binary'
      )
      File.open(file, 'rb')
    end
    
    # Send binary data over HTTP to the user as a file download. May set content type,
    # apparent file name, and specify whether to show data inline or download as an attachment.
    #
    # @param [String] data
    #   Path to file to send to the client.
    #
    # @option :disposition [String]
    #   The disposition of the file send. Defaults to "attachment".
    # @option :filename [String]
    #   The name to use for the file. Defaults to the filename of file.
    # @option :type [String] The content type.
    def send_data(data, opts={})
      opts.update(Merb::Const::DEFAULT_SEND_FILE_OPTIONS.merge(opts))
      disposition = opts[:disposition].dup || 'attachment'
      disposition << %(; filename="#{opts[:filename]}") if opts[:filename]
      headers.update(
        'Content-Type'              => opts[:type].strip,  # fixes a problem with extra '\r' with some browsers
        'Content-Disposition'       => disposition,
        'Content-Transfer-Encoding' => 'binary'
      )
      data
    end
    
    # Streams a file over HTTP.
    #
    # @example
    #   stream_file({ :filename => file_name, :type => content_type,
    #     :content_length => content_length }) do |response|
    #     AWS::S3::S3Object.stream(user.folder_name + "-" + user_file.unique_id, bucket_name) do |chunk|
    #       response.write chunk
    #     end
    #   end
    #
    # @param &stream
    #   A block that, when called, will return an object that responds to
    #   +get_lines+ for streaming.
    #
    # @option :disposition [String]
    #   The disposition of the file send. Defaults to "attachment".
    # @option :type [String]
    #   The content type.
    # @option :content_length [Numeric]
    #   The length of the content to send.
    # @option :filename [String]
    #   The name to use for the streamed file.
    def stream_file(opts={}, &stream)
      must_support_streaming!
      opts.update(Merb::Const::DEFAULT_SEND_FILE_OPTIONS.merge(opts))
      disposition = opts[:disposition].dup || 'attachment'
      disposition << %(; filename="#{opts[:filename]}")
      headers.update(
        'Content-Type'              => opts[:type].strip,  # fixes a problem with extra '\r' with some browsers
        'Content-Disposition'       => disposition,
        'Content-Transfer-Encoding' => 'binary',
        # Rack specification requires header values to respond to :each
        'CONTENT-LENGTH'            => opts[:content_length].to_s
      )
      Proc.new{|response|
        response.send_status(opts[:content_length])
        response.send_header
        stream.call(response)
      }
    end

    # Uses the nginx specific +X-Accel-Redirect+ header to send a file directly
    # from nginx. For more information, see the nginx wiki:
    # http://wiki.codemongers.com/NginxXSendfile
    #
    # @param [String] file
    #   Path to file to send to the client.
    def nginx_send_file(file)
      headers['X-Accel-Redirect'] = file
      return ' '
    end  
  
    # Sets a cookie to be included in the response.
    #
    # If you need to set a cookie, then use the +cookies+ hash.
    #
    # @param [#to_s] name
    #   A name for the cookie.
    # @param [#to_s] value
    #   A value for the cookie.
    # @param [Hash, #gmtime:#strftime] expires
    #   An expiration time for the cookie, or a hash of cookie options.
    # 
    # @api public
    def set_cookie(name, value, expires)
      options = expires.is_a?(Hash) ? expires : {:expires => expires}
      cookies.set_cookie(name, value, options)
    end
    
    # Marks a cookie as deleted and gives it an expires stamp in the past. This
    # method is used primarily internally in Merb.
    #
    # Use the +cookies+ hash to manipulate cookies instead.
    #
    # @param [#to_s] name
    #   A name for the cookie to delete.
    def delete_cookie(name)
      set_cookie(name, nil, Merb::Const::COOKIE_EXPIRED_TIME)
    end
    
    # Escapes the string representation of +obj+ and escapes it for use in XML.
    #
    # @param [#to_s] obj
    #   The object to escape for use in XML.
    #
    # @return [String]
    #   The escaped object.
    def escape_xml(obj)
      Erubis::XmlHelper.escape_xml(obj.to_s)
    end
    alias h escape_xml
    alias html_escape escape_xml
    
    private

    # Checks whether streaming is supported by the current Rack adapter.
    #
    # @raise [NotImplemented]
    #   The Rack adapter doens't support streaming.
    def must_support_streaming!
      unless request.env['rack.streaming']
        raise(Merb::ControllerExceptions::NotImplemented, "Current Rack adapter does not support streaming")
      end
    end

  end
end
