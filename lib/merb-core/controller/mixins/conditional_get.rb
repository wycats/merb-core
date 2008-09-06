module Merb::ConditionalGetMixin

  def etag=(tag)
    headers[Merb::Const::ETAG] = %("#{expand_cache_key(tag)}")
  end

  def etag
    headers[Merb::Const::ETAG]
  end

  def etag_matches?(tag)
    tag == headers[Merb::Const::ETAG]
  end

  def last_modified=(time)
    headers[Merb::Const::LAST_MODIFIED] = time.httpdate
  end
  
  def last_modified
    Time.rfc2822(headers[Merb::Const::LAST_MODIFIED])
  end

  protected

  def expand_cache_key(tag)
    tag
  end
  
end
