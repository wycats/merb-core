require File.join(File.dirname(__FILE__), "..", "..", "lib", "merb-core")

module Merb
  class Responder
    def query_parse(qs, d = '&;', preserve_order = false)
      qh = preserve_order ? Dictionary.new : {}
      (qs||'').split(/[#{d}] */n).inject(qh) { |h,p| 
        key, value = unescape(p).split('=',2)
        normalize_params(h, key, value)
      }
      preserve_order ? qh : qh.to_mash
    end
    
    def query_parse_new(query_string, delimiter = '&;', preserve_order = false)
      query = preserve_order ? Dictionary.new : {}
      (query_string || '').split(/[#{delimiter}] */n).each do |pair|
        key, value = unescape(pair).split('=',2)
        normalize_params(query, key, value)
      end
      preserve_order ? query : query.to_mash
    end
  end
end

require "rubygems"
require "rbench"

test_values = ["foo=bar&baz=bat", "foo[]=bar&foo[]=baz", "foo[][bar]=1&foo[][bar]=2", "foo[bar][][baz]=1&foo[bar][][baz]=2", "foo[1]=bar&foo[2]=baz"]

RBench.run(10_000) do
  report "old_parse" do
    test_values.each { |query| Merb::Request.query_parse(query) }
  end
  
  report "new_parse" do
    test_values.each { |query| Merb::Request.query_parse(query) }
  end  
end