module Merb
  class Request
    attr_accessor :env, :session
    
    # by setting these to false, auto-parsing is disabled; this way you can do your own parsing instead
    cattr_accessor :parse_multipart_params, :parse_json_params, :parse_xml_params
    self.parse_multipart_params = true
    self.parse_json_params = true
    self.parse_xml_params = true
    
    def initialize(http_request)
      @env = http_request.params
      @body = http_request.body
    end
    
    METHODS = %w{get post put delete head}
    
    def method
      @method ||= begin
        request_method = @env['REQUEST_METHOD'].downcase.to_sym
        case request_method
        when :get, :head, :put, :delete
          request_method
        when :post
          if self.class.parse_multipart_params
            m = body_and_query_params.merge(multipart_params)['_method']
          else  
            m = body_and_query_params['_method']
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
      define_method("#{m}?") { method == m.to_sym }
    end
    
    private
    
    # FIXME: symbolize_keys on params is a potential problem. symbols are 
    # not garbage collected so a malicious user could send many large query
    # keys to Merb forcing it to eat up memeory.
    
    # A hash of parameters passed from the URL like ?blah=hello
    def query_params
      @query_params ||= self.class.query_parse(query_string || '')
    end
    
    # A hash of parameters passed in the body of the request.
    #
    # Ajax calls from prototype.js and other libraries 
    # pass content this way.
    def body_params
      @body_params ||= begin
        if content_type && content_type.match(Merb::Const::FORM_URL_ENCODED_REGEXP) # or content_type.nil?
          self.class.query_parse(raw_post)
        end
      end
    end
    
    def body_and_query_params
      # ^-- FIXME a better name for this method
      @body_and_query_params ||= begin
        h = query_params
        h.merge!(body_params) if body_params
        h.to_mash
      end
    end
    
    def multipart_params
      @multipart_params ||= 
        begin
          if Merb::Const::MULTIPART_REGEXP =~ content_type
            if  @body.size <= 0
              {}
            else  
              self.class.parse_multipart(@body, $1, content_length)
            end
          else
            {}
          end
        rescue ControllerExceptions::MultiPartParseError => e
          @multipart_params = {}
          raise e
        end
    end
    
    def json_params
      @json_params ||= begin
        if Merb::Const::JSON_MIME_TYPE_REGEXP.match(content_type)
          JSON.parse(raw_post)
        end
      end
    end
    
    def xml_params
      @xml_params ||= begin
        if Merb::Const::XML_MIME_TYPE_REGEXP.match(content_type)
          Hash.from_xml(raw_post) rescue Mash.new
        end
      end
    end
    
    public
    
    def params
      @params ||= begin
        h = body_and_query_params.merge(route_params)      
        h.merge!(multipart_params) if self.class.parse_multipart_params && multipart_params
        h.merge!(json_params) if self.class.parse_json_params && json_params
        h.merge!(xml_params) if self.class.parse_xml_params && xml_params
        h
      end
    end
    
    def cookies
      @cookies ||= self.class.query_parse(@env[Merb::Const::HTTP_COOKIE], ';,')
    end
    
    def route
      @route ||= Merb::Router.routes[route_index]
    end
    
    # returns two objects, route_index and route_params
    def route_match
      @route_match ||= Merb::Router.match(self, body_and_query_params)
    end
    private :route_match
    
    def route_index
      route_match.first
    end
    
    def route_params
      route_match.last
    end
    
    def controller_name
      if route_params[:namespace]
        route_params[:namespace] + '/' + route_params[:controller]
      else
        route_params[:controller]
      end
    end
    
    def controller_class
      begin
        cnt = controller_name.to_const_string
      rescue ::String::InvalidPathConversion
        raise ControllerExceptions::NotFound
      end
      if !Controller._subclasses.include?(cnt)
        raise ControllerExceptions::NotFound, "Controller '#{cnt}' not found"
      end
      
      begin
        if cnt == "Application"
          raise ControllerExceptions::NotFound, "The 'Application' controller has no public actions" 
        end
        return Object.full_const_get(cnt)
      rescue NameError
        raise ControllerExceptions::NotFound
      end
    end
    
    def action
      route_params[:action]
    end
    
    def raw_post
      @body.rewind
      res = @body.read
      @body.rewind
      res
    end
    
    # Returns true if the request is an Ajax request.
    #
    # Also aliased as the more memorable ajax? and xhr?.
    def xml_http_request?
      not /XMLHttpRequest/i.match(@env['HTTP_X_REQUESTED_WITH']).nil?
    end
    alias xhr? :xml_http_request?
    alias ajax? :xml_http_request?
    
    # returns the remote IP address if it can find it.
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
    
    # returns either 'https://' or 'http://' depending on
    # the HTTPS header
    def protocol
      ssl? ? 'https://' : 'http://'
    end
    
    # returns true if the request is an SSL request
    def ssl?
      @env['HTTPS'] == 'on' || @env['HTTP_X_FORWARDED_PROTO'] == 'https'
    end
    
    # returns the request HTTP_REFERER.
    def referer
      @env['HTTP_REFERER']
    end
    
    # returns he request uri.
    def uri
      @env['REQUEST_URI']
    end
    
    def user_agent
      @env['HTTP_USER_AGENT']
    end

    def server_name
      @env['SERVER_NAME']
    end

    def accept_encoding
      @env['HTTP_ACCEPT_ENCODING']
    end

    def script_name
      @env['SCRIPT_NAME']
    end

    def cache_control
      @env['HTTP_CACHE_CONTROL']
    end

    def accept_language
      @env['HTTP_ACCEPT_LANGUAGE']
    end

    def host
      @env['HTTP_HOST']
    end

    def server_software
      @env['SERVER_SOFTWARE']
    end

    def keep_alive
      @env['HTTP_KEEP_ALIVE']
    end

    def accept_charset
      @env['HTTP_ACCEPT_CHARSET']
    end

    def version
      @env['HTTP_VERSION']
    end

    def gateway
      @env['GATEWAY_INTERFACE']
    end

    def accept
      @env['HTTP_ACCEPT'].blank? ? "*/*" : @env['HTTP_ACCEPT']
    end

    def connection
      @env['HTTP_CONNECTION']
    end

    def query_string
      @env['QUERY_STRING']  
    end
    
    def content_type
      @env['CONTENT_TYPE']
    end
    
    def content_length
      @content_length ||= @env[Merb::Const::CONTENT_LENGTH].to_i
    end
    
    # Returns the uri without the query string. Strips trailing '/' and reduces
    # duplicate '/' to a single '/'
    def path
      path = (uri ? uri.split('?').first : '').sub(/\/+/, '/')
      path = path[0..-2] if (path[-1] == ?/) && path.size > 1
      path
    end
    
    # returns the PATH_INFO
    def path_info
      @path_info ||= Mongrel::HttpRequest.unescape(@env['PATH_INFO'])
    end
    
    # returns the port the server is running on
    def port
      @env['SERVER_PORT'].to_i
    end
    
    # returns the full hostname including port
    def host
      @env['HTTP_X_FORWARDED_HOST'] || @env['HTTP_HOST'] 
    end
    
    # returns an array of all the subdomain parts of the host.
    def subdomains(tld_length = 1)
      parts = host.split('.')
      parts[0..-(tld_length+2)]
    end
    
    # returns the full domain name without the port number.
    def domain(tld_length = 1)
      host.split('.').last(1 + tld_length).join('.').sub(/:\d+$/,'')
    end
    
    class << self
      # Escapes +s+ for use in a URL.
      #
      # ==== Parameter
      #
      # +s+ - String to URL escape.
      #
      def escape(s)
        s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
          '%'+$1.unpack('H2'*$1.size).join('%').upcase
        }.tr(' ', '+')
      end

      # Unescapes a string (i.e., reverse URL escaping).
      #
      # ==== Parameter 
      #
      # +s+ - String to unescape.
      #
      def unescape(s)
        s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){
          [$1.delete('%')].pack('H*')
        }
      end
      
      # parses a query string or the payload of a POST
      # request into the params hash. So for example:
      # /foo?bar=nik&post[title]=heya&post[body]=whatever
      # parses into:
      # {:bar => 'nik', :post => {:title => 'heya', :body => 'whatever'}}
      def query_parse(qs, d = '&;')
        (qs||'').split(/[#{d}] */n).inject({}) { |h,p| 
          normalize_params(h, *unescape(p).split('=',2))
        }.to_mash
      end
    
      NAME_REGEX = /Content-Disposition:.* name="?([^\";]*)"?/ni.freeze
      CONTENT_TYPE_REGEX = /Content-Type: (.*)\r\n/ni.freeze
      FILENAME_REGEX = /Content-Disposition:.* filename="?([^\";]*)"?/ni.freeze
      CRLF = "\r\n".freeze
      EOL = CRLF
      def parse_multipart(request,boundary, content_length)
        boundary = "--#{boundary}"
        paramhsh = {}
        buf = ""
        input = request
        input.binmode if defined? input.binmode
        boundary_size = boundary.size + EOL.size
        bufsize = 16384
        content_length -= boundary_size
        status = input.read(boundary_size)
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
      
      def normalize_params(parms, name, val=nil)
        name =~ %r([\[\]]*([^\[\]]+)\]*)
        key = $1 || ''
        after = $' || ''
        
        if after == ""
          parms[key] = val
        elsif after == "[]"
          (parms[key] ||= []) << val
        else
          parms[key] ||= {}
          parms[key] = normalize_params(parms[key], after, val)
        end
        parms
      end
    end
  end
end    
    
