module Merb

  module StatusCodes

    STATUS_CODES = []

    class Base
      def self.status; nil end

      class << self
        alias :to_i :status
        
        def inherited(subclass)
          STATUS_CODES << {
            :child_class => subclass,
            :child_name  => subclass.to_s.split('::').last,
            :parent_name => self.to_s.split('::').last
          }
          # Note: Since inherited fires immediately after the subclass
          # definition itself -- but before the definition of methods inside,
          # we cannot set :status here.
        end
      end
    end

    # ===== 1xx
    class Informational               < Merb::StatusCodes::Base; end
    class Continue                    < Merb::StatusCodes::Informational; def self.status; 100 end end
    class SwitchingProtocols          < Merb::StatusCodes::Informational; def self.status; 101 end end

    # ===== 2xx
    class Successful                  < Merb::StatusCodes::Base; end
    class OK                          < Merb::StatusCodes::Successful; def self.status; 200 end end
    class Created                     < Merb::StatusCodes::Successful; def self.status; 201 end end
    class Accepted                    < Merb::StatusCodes::Successful; def self.status; 202 end end
    class NonAuthoritativeInformation < Merb::StatusCodes::Successful; def self.status; 203 end end
    class NoContent                   < Merb::StatusCodes::Successful; def self.status; 204 end end
    class ResetContent                < Merb::StatusCodes::Successful; def self.status; 205 end end
    class PartialContent              < Merb::StatusCodes::Successful; def self.status; 206 end end

    # ===== 3xx
    class Redirection                 < Merb::StatusCodes::Base; end
    class MultipleChoices             < Merb::StatusCodes::Redirection; def self.status; 300 end end
    class MovedPermanently            < Merb::StatusCodes::Redirection; def self.status; 301 end end
    class Found                       < Merb::StatusCodes::Redirection; def self.status; 302 end end # HTTP 1.1
    class MovedTemporarily            < Merb::StatusCodes::Redirection; def self.status; 302 end end # HTTP 1.0
    class SeeOther                    < Merb::StatusCodes::Redirection; def self.status; 303 end end
    class NotModified                 < Merb::StatusCodes::Redirection; def self.status; 304 end end
    class UseProxy                    < Merb::StatusCodes::Redirection; def self.status; 305 end end
    class TemporaryRedirect           < Merb::StatusCodes::Redirection; def self.status; 307 end end

    # ===== 4xx
    class ClientError                 < Merb::StatusCodes::Base; end
    class BadRequest                  < Merb::StatusCodes::ClientError; def self.status; 400 end end
    class MultiPartParseError         < Merb::StatusCodes::BadRequest; end
    class Unauthorized                < Merb::StatusCodes::ClientError; def self.status; 401 end end
    class PaymentRequired             < Merb::StatusCodes::ClientError; def self.status; 402 end end
    class Forbidden                   < Merb::StatusCodes::ClientError; def self.status; 403 end end
    class NotFound                    < Merb::StatusCodes::ClientError; def self.status; 404 end end
    class ActionNotFound              < Merb::StatusCodes::NotFound; end
    class TemplateNotFound            < Merb::StatusCodes::NotFound; end
    class LayoutNotFound              < Merb::StatusCodes::NotFound; end
    class MethodNotAllowed            < Merb::StatusCodes::ClientError; def self.status; 405 end end
    class NotAcceptable               < Merb::StatusCodes::ClientError; def self.status; 406 end end
    class ProxyAuthenticationRequired < Merb::StatusCodes::ClientError; def self.status; 407 end end
    class RequestTimeout              < Merb::StatusCodes::ClientError; def self.status; 408 end end
    class Conflict                    < Merb::StatusCodes::ClientError; def self.status; 409 end end
    class Gone                        < Merb::StatusCodes::ClientError; def self.status; 410 end end
    class LengthRequired              < Merb::StatusCodes::ClientError; def self.status; 411 end end
    class PreconditionFailed          < Merb::StatusCodes::ClientError; def self.status; 412 end end
    class RequestEntityTooLarge       < Merb::StatusCodes::ClientError; def self.status; 413 end end
    class RequestURITooLarge          < Merb::StatusCodes::ClientError; def self.status; 414 end end
    class UnsupportedMediaType        < Merb::StatusCodes::ClientError; def self.status; 415 end end
    class RequestRangeNotSatisfiable  < Merb::StatusCodes::ClientError; def self.status; 416 end end
    class ExpectationFailed           < Merb::StatusCodes::ClientError; def self.status; 417 end end

    # ===== 5xx
    class ServerError                 < Merb::StatusCodes::Base; end
    class InternalServerError         < Merb::StatusCodes::ServerError; def self.status; 500 end end
    class NotImplemented              < Merb::StatusCodes::ServerError; def self.status; 501 end end
    class BadGateway                  < Merb::StatusCodes::ServerError; def self.status; 502 end end
    class ServiceUnavailable          < Merb::StatusCodes::ServerError; def self.status; 503 end end
    class GatewayTimeout              < Merb::StatusCodes::ServerError; def self.status; 504 end end
    class HTTPVersionNotSupported     < Merb::StatusCodes::ServerError; def self.status; 505 end end

    STATUS_CODES.each do |item|
      item[:status] = item[:child_class].status
    end

  end # StatusCodes
  
end # Merb
