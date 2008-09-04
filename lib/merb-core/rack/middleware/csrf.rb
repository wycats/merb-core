require 'digest/md5'

module Merb
  module Rack

    class Csrf < Merb::Rack::Middleware
      HTML_TYPES = %w(text/html application/xhtml+xml)
      POST_FORM_RE = Regexp.compile('(<form\W[^>]*\bmethod=(\'|"|)POST(\'|"|)\b[^>]*>)', Regexp::IGNORECASE)
      ERROR_MSG = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"><body><h1>403 Forbidden</h1><p>Cross Site Request Forgery detected. Request aborted.</p></body></html>'.freeze

      def call(env)
        status, header, body = @app.call(env)

        if env[Merb::Const::REQUEST_METHOD] == Merb::Const::GET
          body = process_response(body) if valid_content_type?(header[Merb::Const::CONTENT_TYPE])
        elsif env[Merb::Const::REQUEST_METHOD] == Merb::Const::POST
          status, body = process_request(env, status, body)
        end

        [status, header, body]
      end

      private
      def process_request(env, status, body)
        session_id = Merb::Config[:session_id_key]
        csrf_token = _make_token(session_id)

        request_csrf_token = env['csrf_authentication_token']

        unless csrf_token == request_csrf_token
          exception = Merb::ControllerExceptions::Forbidden.new(ERROR_MSG)
          status = exception.status
          body = exception.message

          return [status, body]
        end

        return [status, body]
      end

      def process_response(body)
        session_id = Merb::Config[:session_id_key]
        csrf_token = _make_token(session_id)

        if csrf_token
          modified_body = ''
          body.scan(POST_FORM_RE) do |match|
            modified_body << add_csrf_field($~, csrf_token)
          end

          body = modified_body
        end

        body
      end

      def add_csrf_field(match, csrf_token)
        modified_body = match.pre_match
        modified_body << match.to_s
        modified_body << "<div style='display: none;'><input type='hidden' id='csrf_authentication_token' name='csrf_authentication_token' value='#{csrf_token}' /></div>"
        modified_body << match.post_match
      end

      def valid_content_type?(content_type)
        HTML_TYPES.include?(content_type.split(';').first)
      end

      def _make_token(session_id)
        Digest::MD5.hexdigest(Merb::Config[:session_secret_key] + session_id)
      end
    end
  end
end
