require 'tempfile'

module Merb
  
  class Request
    # def env def exceptions def route_params
    attr_accessor :env, :exceptions, :route
    attr_reader :route_params
    
    # by setting these to false, auto-parsing is disabled; this way you can
    # do your own parsing instead
    cattr_accessor :parse_multipart_params, :parse_json_params,
      :parse_xml_params
    self.parse_multipart_params = true
    self.parse_json_params = true
    self.parse_xml_params = true
    
    # Flash, and some older browsers can't use arbitrary
    # request methods -- i.e., are limited to GET/POST.
    # These user-agents can make POST requests in combination
    # with these overrides to participate fully in REST.
    # Common examples are _method or fb_sig_request_method
    # in the params, or an X-HTTP-Method-Override header
    cattr_accessor :http_method_overrides
    self.http_method_overrides = []
    
    # Initialize the request object.
    #
    # ==== Parameters
    # http_request<~params:~[], ~body:IO>:: 
    #   An object like an HTTP Request.
    def initialize(rack_env)
      @env  = rack_env
      @body = rack_env['rack.input']
      @route_params = {}
    end
    
    def controller
      unless params[:controller]
        raise ControllerExceptions::NotFound, 
          "Route matched, but route did not specify a controller.\n" +
          "Did you forgot to add :controller => \"people\" or :controller " +
          "segment to route definition?\nHere is what's specified:\n" + 
          request.route_params.inspect
      end
      path = [params[:namespace], params[:controller]].compact.join("/")
      controller = path.snake_case.to_const_string
      
      begin
        Object.full_const_get(controller)
      rescue NameError => e
        msg = "Controller class not found for controller `#{path}'"
        Merb.logger.warn!(msg)
        raise ControllerExceptions::NotFound, msg
      end
    end
    
    METHODS = %w{get post put delete head options}

    # ==== Returns
    # <Symbol>:: The name of the request method, e.g. :get.
    #
    # ==== Notes
    # If the method is post, then the blocks specified in
    # http_method_overrides will be checked for the masquerading method.
    # The block will get the controller yielded to it.  The first matching workaround wins.
    # To disable this behavior, set http_method_overrides = []
    def method
      @method ||= begin
        request_method = @env['REQUEST_METHOD'].downcase.to_sym
        case request_method
        when :get, :head, :put, :delete, :options
          request_method
        when :post
          m = nil
          self.class.http_method_overrides.each do |o|
            m ||= o.call(self); break if m
          end
          m.downcase! if m
          METHODS.include?(m) ? m.to_sym : :post
        else
          raise "Unknown REQUEST_METHOD: #{@env['REQUEST_METHOD']}"
        end
      end
    end
    
    # create predicate methods for querying the REQUEST_METHOD
    # get? post? head? put? etc
    METHODS.each do |m|
      class_eval "def #{m}?() method == :#{m} end"
    end

    # Find route using requested URI and merges route
    # parameters (:action, :controller and named segments)
    # into request params hash.
    def find_route!
      @route, @route_params = Merb::Router.route_for(self)
      @params.merge! @route_params
    end

    # Redirect status of route matched this request.
    #
    # ==== Returns
    # Integer::
    #   The URL to redirect to if the route redirects
    def redirect_status
      route.redirect_status
    end

    # Returns redirect url of route matched this request.
    #
    # ==== Returns
    # <String>:: redirect url of route matched this request
    def redirect_url
      route.redirect_url
    end

    # Returns true if matched route does immediate redirection.
    #
    # ==== Returns
    # <Boolean>:: if matched route does immediate redirection.
    def redirects?
      route.redirects?
    end
    
    private
    
    # ==== Returns
    # Hash:: Parameters passed from the URL like ?blah=hello.
    def query_params
      @query_params ||= self.class.query_parse(query_string || '')
    end
    
    # Parameters passed in the body of the request. Ajax calls from
    # prototype.js and other libraries pass content this way.
    #
    # ==== Returns
    # Hash:: The parameters passed in the body.
    def body_params
      @body_params ||= begin
        if content_type && content_type.match(Merb::Const::FORM_URL_ENCODED_REGEXP) # or content_type.nil?
          self.class.query_parse(raw_post)
        end
      end
    end

    # ==== Returns
    # Mash::
    #   The parameters gathered from the query string and the request body,
    #   with parameters in the body taking precedence.
    def body_and_query_params
      # ^-- FIXME a better name for this method
      @body_and_query_params ||= begin
        h = query_params
        h.merge!(body_params) if body_params
        h.to_mash
      end
    end

    # ==== Raises
    # ControllerExceptions::MultiPartParseError::
    #   Unable to parse the multipart form data.
    #
    # ==== Returns
    # Hash:: The parsed multipart parameters.
    def multipart_params
      @multipart_params ||= 
        begin
          # if the content-type is multipart
          # parse the multipart. Otherwise return {}
          if (Merb::Const::MULTIPART_REGEXP =~ content_type)
            self.class.parse_multipart(@body, $1, content_length)
          else
            {}
          end  
        rescue ControllerExceptions::MultiPartParseError => e
          @multipart_params = {}
          raise e
        end
    end

    # ==== Returns
    # Hash:: Parameters from body if this is a JSON request.
    #
    # ==== Notes
    # If the JSON object parses as a Hash, it will be merged with the
    # parameters hash.  If it parses to anything else (such as an Array, or
    # if it inflates to an Object) it will be accessible via the inflated_object
    # parameter.
    def json_params
      @json_params ||= begin
        if Merb::Const::JSON_MIME_TYPE_REGEXP.match(content_type)
          jobj = JSON.parse(raw_post) rescue Mash.new
          jobj.kind_of?(Hash) ? jobj : { :inflated_object => jobj }
        end
      end
    end

    # ==== Returns
    # Hash:: Parameters from body if this is an XML request.
    def xml_params
      @xml_params ||= begin
        if Merb::Const::XML_MIME_TYPE_REGEXP.match(content_type)
          Hash.from_xml(raw_post) rescue Mash.new
        end
      end
    end
    
    public
    
    # ==== Returns
    # Mash:: All request parameters.
    #
    # ==== Notes
    # The order of precedence for the params is XML, JSON, multipart, body and
    # request string.
    def params
      @params ||= begin
        h = body_and_query_params.merge(route_params)      
        h.merge!(multipart_params) if self.class.parse_multipart_params && multipart_params
        h.merge!(json_params) if self.class.parse_json_params && json_params
        h.merge!(xml_params) if self.class.parse_xml_params && xml_params
        h
      end
    end
    
    def message
      return {} unless params[:_message]
      begin
        Marshal.load(Merb::Request.unescape(params[:_message]).unpack("m").first)
      rescue ArgumentError
        {}
      end
    end

    # Resets the params to a nil value.
    def reset_params!
      @params = nil
    end
    
    # ==== Returns
    # String:: The raw post.
    def raw_post
      @body.rewind if @body.respond_to?(:rewind)
      @raw_post ||= @body.read
    end
    
    # ==== Returns
    # Boolean:: If the request is an XML HTTP request.
    def xml_http_request?
      not /XMLHttpRequest/i.match(@env['HTTP_X_REQUESTED_WITH']).nil?
    end
    alias xhr? :xml_http_request?
    alias ajax? :xml_http_request?
    
    # ==== Returns
    # String:: The remote IP address.
    def remote_ip
      return @env['HTTP_CLIENT_IP'] if @env.include?('HTTP_CLIENT_IP')
    
      if @env.include?(Merb::Const::HTTP_X_FORWARDED_FOR) then
        remote_ips = @env[Merb::Const::HTTP_X_FORWARDED_FOR].split(',').reject do |ip|
          ip =~ /^unknown$|^(127|10|172\.16|192\.168)\./i
        end
    
        return remote_ips.first.strip unless remote_ips.empty?
      end
    
      return @env[Merb::Const::REMOTE_ADDR]
    end
    
    # ==== Returns
    # String::
    #   The protocol, i.e. either "https://" or "http://" depending on the
    #   HTTPS header.
    def protocol
      ssl? ? 'https://' : 'http://'
    end
    
    # ==== Returns
    # Boolean::: True if the request is an SSL request.
    def ssl?
      @env['HTTPS'] == 'on' || @env['HTTP_X_FORWARDED_PROTO'] == 'https'
    end
    
    # ==== Returns
    # String:: The HTTP referer.
    def referer
      @env['HTTP_REFERER']
    end
    
    # ==== Returns
    # String:: The full URI, including protocol and host
    def full_uri
      protocol + host + uri
    end
    
    # ==== Returns
    # String:: The request URI.
    def uri
      @env['REQUEST_PATH'] || @env['REQUEST_URI'] || path_info
    end

    # ==== Returns
    # String:: The HTTP user agent.
    def user_agent
      @env['HTTP_USER_AGENT']
    end

    # ==== Returns
    # String:: The server name.
    def server_name
      @env['SERVER_NAME']
    end

    # ==== Returns
    # String:: The accepted encodings.
    def accept_encoding
      @env['HTTP_ACCEPT_ENCODING']
    end

    # ==== Returns
    # String:: The script name.
    def script_name
      @env['SCRIPT_NAME']
    end

    # ==== Returns
    # String:: HTTP cache control.
    def cache_control
      @env['HTTP_CACHE_CONTROL']
    end

    # ==== Returns
    # String:: The accepted language.
    def accept_language
      @env['HTTP_ACCEPT_LANGUAGE']
    end

    # ==== Returns
    # String:: The server software.
    def server_software
      @env['SERVER_SOFTWARE']
    end

    # ==== Returns
    # String:: Value of HTTP_KEEP_ALIVE.
    def keep_alive
      @env['HTTP_KEEP_ALIVE']
    end

    # ==== Returns
    # String:: The accepted character sets.
    def accept_charset
      @env['HTTP_ACCEPT_CHARSET']
    end

    # ==== Returns
    # String:: The HTTP version
    def version
      @env['HTTP_VERSION']
    end

    # ==== Returns
    # String:: The gateway.
    def gateway
      @env['GATEWAY_INTERFACE']
    end

    # ==== Returns
    # String:: The accepted response types. Defaults to "*/*".
    def accept
      @env['HTTP_ACCEPT'].blank? ? "*/*" : @env['HTTP_ACCEPT']
    end

    # ==== Returns
    # String:: The HTTP connection.
    def connection
      @env['HTTP_CONNECTION']
    end

    # ==== Returns
    # String:: The query string.
    def query_string
      @env['QUERY_STRING']  
    end

    # ==== Returns
    # String:: The request content type.
    def content_type
      @env['CONTENT_TYPE']
    end

    # ==== Returns
    # Fixnum:: The request content length.
    def content_length
      @content_length ||= @env[Merb::Const::CONTENT_LENGTH].to_i
    end
    
    # ==== Returns
    # String::
    #   The URI without the query string. Strips trailing "/" and reduces
    #   duplicate "/" to a single "/".
    def path
      path = (uri.empty? ? '/' : uri.split('?').first).squeeze("/")
      path = path[0..-2] if (path[-1] == ?/) && path.size > 1
      path
    end
    
    # ==== Returns
    # String:: The path info.
    def path_info
      @path_info ||= self.class.unescape(@env['PATH_INFO'])
    end
    
    # ==== Returns
    # Fixnum:: The server port.
    def port
      @env['SERVER_PORT'].to_i
    end
    
    # ==== Returns
    # String:: The full hostname including the port.
    def host
      @env['HTTP_X_FORWARDED_HOST'] || @env['HTTP_HOST'] 
    end
    
    # ==== Parameters
    # tld_length<Fixnum>::
    #   Number of domains levels to inlclude in the top level domain. Defaults
    #   to 1.
    #
    # ==== Returns
    # Array:: All the subdomain parts of the host.
    def subdomains(tld_length = 1)
      parts = host.split('.')
      parts[0..-(tld_length+2)]
    end
    
    # ==== Parameters
    # tld_length<Fixnum>::
    #   Number of domains levels to inlclude in the top level domain. Defaults
    #   to 1.
    #
    # ==== Returns
    # String:: The full domain name without the port number.
    def domain(tld_length = 1)
      host.split('.').last(1 + tld_length).join('.').sub(/:\d+$/,'')
    end

    # ==== Returns
    # Value of If-None-Match request header.
    def if_none_match
      @env[Merb::Const::HTTP_IF_NONE_MATCH]
    end

    # ==== Returns
    # Value of If-Modified-Since request header.
    def if_modified_since
      if time = @env[Merb::Const::HTTP_IF_MODIFIED_SINCE]
        Time.rfc2822(time)
      end
    end
    
    class << self
      
      # ==== Parameters
      # value<Array, Hash, Dictionary ~to_s>:: The value for the query string.
      # prefix<~to_s>:: The prefix to add to the query string keys.
      #
      # ==== Returns
      # String:: The query string.
      #
      # ==== Alternatives
      # If the value is a string, the prefix will be used as the key.
      #
      # ==== Examples
      #   params_to_query_string(10, "page")
      #     # => "page=10"
      #   params_to_query_string({ :page => 10, :word => "ruby" })
      #     # => "page=10&word=ruby"
      #   params_to_query_string({ :page => 10, :word => "ruby" }, "search")
      #     # => "search[page]=10&search[word]=ruby"
      #   params_to_query_string([ "ice-cream", "cake" ], "shopping_list")
      #     # => "shopping_list[]=ice-cream&shopping_list[]=cake"
      def params_to_query_string(value, prefix = nil)
        case value
        when Array
          value.map { |v|
            params_to_query_string(v, "#{prefix}[]")
          } * "&"
        when Hash, Dictionary
          value.map { |k, v|
            params_to_query_string(v, prefix ? "#{prefix}[#{Merb::Request.escape(k)}]" : Merb::Request.escape(k))
          } * "&"
        else
          "#{prefix}=#{Merb::Request.escape(value)}"
        end
      end
      
      # ==== Parameters
      # s<String>:: String to URL escape.
      #
      # ==== returns
      # String:: The escaped string.
      def escape(s)
        s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
          '%'+$1.unpack('H2'*$1.size).join('%').upcase
        }.tr(' ', '+')
      end

      # ==== Parameter
      # s<String>:: String to URL unescape.
      #
      # ==== returns
      # String:: The unescaped string.
      def unescape(s)
        s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){
          [$1.delete('%')].pack('H*')
        }
      end
      
      # ==== Parameters
      # query_string<String>:: The query string.
      # delimiter<String>:: The query string divider. Defaults to "&".
      # preserve_order<Boolean>:: Preserve order of args. Defaults to false.
      #
      # ==== Returns
      # Mash:: The parsed query string (Dictionary if preserve_order is set).
      #
      # ==== Examples
      #   query_parse("bar=nik&post[body]=heya")
      #     # => { :bar => "nik", :post => { :body => "heya" } }
      def query_parse(query_string, delimiter = '&;', preserve_order = false)
        query = preserve_order ? Dictionary.new : {}
        for pair in (query_string || '').split(/[#{delimiter}] */n)
          key, value = unescape(pair).split('=',2)
          normalize_params(query, key, value)
        end
        preserve_order ? query : query.to_mash
      end
    
      NAME_REGEX = /Content-Disposition:.* name="?([^\";]*)"?/ni.freeze
      CONTENT_TYPE_REGEX = /Content-Type: (.*)\r\n/ni.freeze
      FILENAME_REGEX = /Content-Disposition:.* filename="?([^\";]*)"?/ni.freeze
      CRLF = "\r\n".freeze
      EOL = CRLF

      # ==== Parameters
      # request<IO>:: The raw request.
      # boundary<String>:: The boundary string.
      # content_length<Fixnum>:: The length of the content.
      #
      # ==== Raises
      # ControllerExceptions::MultiPartParseError:: Failed to parse request.
      #
      # ==== Returns
      # Hash:: The parsed request.
      def parse_multipart(request, boundary, content_length)
        boundary = "--#{boundary}"
        paramhsh = {}
        buf = ""
        input = request
        input.binmode if defined? input.binmode
        boundary_size = boundary.size + EOL.size
        bufsize = 16384
        content_length -= boundary_size
        status = input.read(boundary_size)
        return {} if status == nil || status.empty?
        raise ControllerExceptions::MultiPartParseError, "bad content body:\n'#{status}' should == '#{boundary + EOL}'"  unless status == boundary + EOL
        rx = /(?:#{EOL})?#{Regexp.quote(boundary,'n')}(#{EOL}|--)/
        loop {
          head = nil
          body = ''
          filename = content_type = name = nil
          read_size = 0
          until head && buf =~ rx
            i = buf.index("\r\n\r\n")
            if( i == nil && read_size == 0 && content_length == 0 )
              content_length = -1
              break
            end
            if !head && i
              head = buf.slice!(0, i+2) # First \r\n
              buf.slice!(0, 2)          # Second \r\n
              filename = head[FILENAME_REGEX, 1]
              content_type = head[CONTENT_TYPE_REGEX, 1]
              name = head[NAME_REGEX, 1]
            
              if filename && !filename.empty?
                body = Tempfile.new(:Merb)
                body.binmode if defined? body.binmode
              end
              next
            end
          
            # Save the read body part.
            if head && (boundary_size+4 < buf.size)
              body << buf.slice!(0, buf.size - (boundary_size+4))
            end
          
            read_size = bufsize < content_length ? bufsize : content_length
            if( read_size > 0 )
              c = input.read(read_size)
              raise ControllerExceptions::MultiPartParseError, "bad content body"  if c.nil? || c.empty?
              buf << c
              content_length -= c.size
            end
          end
        
          # Save the rest.
          if i = buf.index(rx)
            body << buf.slice!(0, i)
            buf.slice!(0, boundary_size+2)
          
            content_length = -1  if $1 == "--"
          end
        
          if filename && !filename.empty?   
            body.rewind
            data = { 
              :filename => File.basename(filename),  
              :content_type => content_type,  
              :tempfile => body, 
              :size => File.size(body.path) 
            }
          else
            data = body
          end
          paramhsh = normalize_params(paramhsh,name,data)
          break  if buf.empty? || content_length == -1
        }
        paramhsh
      end

      # Converts a query string snippet to a hash and adds it to existing
      # parameters.
      #
      # ==== Parameters
      # parms<Hash>:: Parameters to add the normalized parameters to.
      # name<String>:: The key of the parameter to normalize.
      # val<String>:: The value of the parameter.
      #
      # ==== Returns
      # Hash:: Normalized parameters
      def normalize_params(parms, name, val=nil)
        name =~ %r([\[\]]*([^\[\]]+)\]*)
        key = $1 || ''
        after = $' || ''
        
        if after == ""
          parms[key] = val
        elsif after == "[]"
          (parms[key] ||= []) << val
        elsif after =~ %r(^\[\])
          parms[key] ||= []
          parms[key] << normalize_params({}, after, val)
        else
          parms[key] ||= {}
          parms[key] = normalize_params(parms[key], after, val)
        end
        parms
      end
    end
  end
end    
