# Provides conditional get support in Merb core.
# Conditional get support is intentionally
# simple and does not do fancy stuff like making
# ETag value from Ruby objects for you.
#
# The most interesting method for end user is
# +request_fresh?+ that is used after setting of
# last modification time or ETag:
#
# ==== Example
#
# def show
#   self.etag = Digest::SHA1.hexdigest(calculate_cache_key(params))
#
#   if request_fresh?
#     self.status = 304
#     return ''
#   else
#     @product = Product.get(params[:id])
#     display @product
#   end
# end
module Merb::ConditionalGetMixin

  # Sets ETag response header by calling
  # #to_s on the argument.
  #
  # ==== Parameters
  # tag<~to_s>::
  #   value of ETag header enclosed in double quotes
  #   as required by the RFC
  def etag=(tag)
    headers[Merb::Const::ETAG] = %("#{tag}")
  end

  # ==== Returns
  # <String>::
  #   Value of ETag response header or nil if it's not set.
  def etag
    headers[Merb::Const::ETAG]
  end

  # ==== Returns
  # <Boolean>::
  # true if ETag response header equals If-None-Match request header,
  # false otherwise
  def etag_matches?(tag = self.etag)
    tag == self.request.if_none_match
  end

  # Sets Last-Modified response header.
  #
  # ==== Parameters
  # tag<Time>::
  # resource modification timestamp converted into format
  # required by the RFC
  def last_modified=(time)
    headers[Merb::Const::LAST_MODIFIED] = time.httpdate
  end

  # ==== Returns
  # <String>::
  #   Value of Last-Modified response header or nil if it's not set.
  def last_modified
    Time.rfc2822(headers[Merb::Const::LAST_MODIFIED])
  end

  # ==== Returns
  # <Boolean>::
  # true if Last-Modified response header is < than
  # If-Modified-Since request header value, false otherwise.
  def not_modified?(time = self.last_modified)
    request.if_modified_since && time && time <= request.if_modified_since
  end

  # ==== Returns
  # <Boolean>::
  # true if either ETag matches or entity is not modified,
  # so request is fresh; false otherwise
  def request_fresh?
    etag_matches?(self.etag) || not_modified?(self.last_modified)
  end
end
