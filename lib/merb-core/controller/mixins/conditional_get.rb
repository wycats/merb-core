module Merb::ConditionalGetMixin

  def etag=(tag)
    headers[Merb::Const::ETAG] = %("#{tag}")
  end

  def etag
    headers[Merb::Const::ETAG]
  end

  def etag_matches?(tag = self.etag)
    tag == self.request.if_none_match
  end

  def last_modified=(time)
    headers[Merb::Const::LAST_MODIFIED] = time.httpdate
  end

  def last_modified
    Time.rfc2822(headers[Merb::Const::LAST_MODIFIED])
  end

  def not_modified?(time = self.last_modified)
    request.if_modified_since && time && time <= request.if_modified_since
  end

  def request_fresh?
    etag_matches?(self.etag) || not_modified?(self.last_modified)
  end
end
