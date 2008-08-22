require File.join(File.dirname(__FILE__), "..", "..", "lib", "merb-core")

module Merb
  class Request
    def self.query_parse(qs, d = '&;', preserve_order = false)
      qh = preserve_order ? Dictionary.new : {}
      (qs||'').split(/[#{d}] */n).inject(qh) { |h,p| 
        key, value = unescape(p).split('=',2)
        normalize_params(h, key, value)
      }
      preserve_order ? qh : qh.to_mash
    end
    
    def self.query_parse2(query_string, delimiter = '&;', preserve_order = false)
      query = preserve_order ? Dictionary.new : {}
      (query_string || '').split(/[#{delimiter}] */n).each do |pair|
        key, value = unescape(pair).split('=',2)
        normalize_params(query, key, value)
      end
      preserve_order ? query : query.to_mash
    end

    def self.query_parse3(query_string, delimiter = '&;', preserve_order = false)
      query = preserve_order ? Dictionary.new : {}
      for pair in (query_string || '').split(/[#{delimiter}] */n)
        key, value = unescape(pair).split('=',2)
        normalize_params(query, key, value)
      end
      preserve_order ? query : query.to_mash
    end
  end
end

require "rubygems"
require "rbench"

test_values = ["foo=bar&baz=bat",
               "foo[]=bar&foo[]=baz",
               "foo[][bar]=1&foo[][bar]=2",
               "foo[bar][][baz]=1&foo[bar][][baz]=2",
               "foo[1]=bar&foo[2]=baz",
               "ie=UTF8&tag=mozilla-20&index=blended&link_code=qs&field-keywords=Freakonomics&sourceid=Mozilla-search",
              "ie=UTF8&rs=&keywords=Freakonomics&rh=i%3Aaps%2Ck%3AFreakonomics%2Ci%3Astripbooks",
               "ie=UTF8&s=books&qid=1219220040&sr=1-2",
              "id=285260960&v0=WWW-NAUS-ITUWEEKLY-OVERVIEW"]

RBench.run(10_000) do
  report "parse1" do
    test_values.each { |query| Merb::Request.query_parse(query) }
  end
  
  report "parse2" do
    test_values.each { |query| Merb::Request.query_parse2(query) }
  end

  report "parse3" do
    test_values.each { |query| Merb::Request.query_parse3(query) }
  end
end
