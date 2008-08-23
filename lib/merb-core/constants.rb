# Most of this list is simply constants frozen for efficiency
module Merb
    module Const
    
    DEFAULT_SEND_FILE_OPTIONS = {
      :type         => 'application/octet-stream'.freeze,
      :disposition  => 'attachment'.freeze
    }.freeze
    
    SET_COOKIE               = " %s=%s; path=/; expires=%s".freeze
    COOKIE_EXPIRATION_FORMAT = "%a, %d-%b-%Y %H:%M:%S GMT".freeze
    COOKIE_SPLIT             = /[;,] */n.freeze
    COOKIE_REGEXP            = /\s*(.+)=(.*)\s*/.freeze
    COOKIE_EXPIRED_TIME      = Time.at(0).freeze
    HOUR                     = 60 * 60
    DAY                      = HOUR * 24
    WEEK                     = DAY * 7
    MULTIPART_REGEXP         = /\Amultipart\/form-data.*boundary=\"?([^\";,]+)/n.freeze
    HTTP_COOKIE              = 'HTTP_COOKIE'.freeze
    QUERY_STRING             = 'QUERY_STRING'.freeze
    JSON_MIME_TYPE_REGEXP    = %r{^application/json|^text/x-json}.freeze
    XML_MIME_TYPE_REGEXP     = %r{^application/xml|^text/xml}.freeze
    FORM_URL_ENCODED_REGEXP  = %r{^application/x-www-form-urlencoded}.freeze
    UPCASE_CONTENT_TYPE      = 'CONTENT_TYPE'.freeze
    CONTENT_TYPE             = "Content-Type".freeze
    DATE                     = 'Date'.freeze
    ETAG                     = 'ETag'.freeze
    LAST_MODIFIED            = "Last-Modified".freeze
    SLASH                    = "/".freeze
    REQUEST_METHOD           = "REQUEST_METHOD".freeze
    GET                      = "GET".freeze
    POST                     = "POST".freeze
    HEAD                     = "HEAD".freeze
    CONTENT_LENGTH           = "CONTENT_LENGTH".freeze
    HTTP_X_FORWARDED_FOR     = "HTTP_X_FORWARDED_FOR".freeze
    HTTP_IF_MODIFIED_SINCE   = "HTTP_IF_MODIFIED_SINCE".freeze
    HTTP_IF_NONE_MATCH       = "HTTP_IF_NONE_MATCH".freeze
    UPLOAD_ID                = "upload_id".freeze
    PATH_INFO                = "PATH_INFO".freeze
    SCRIPT_NAME              = "SCRIPT_NAME".freeze
    REQUEST_URI              = "REQUEST_URI".freeze
    REQUEST_PATH             = "REQUEST_PATH".freeze
    REMOTE_ADDR              = "REMOTE_ADDR".freeze
  end
end
