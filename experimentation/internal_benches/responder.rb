require File.join(File.dirname(__FILE__), "..", "lib", "merb-core")

module Merb
  class Responder
    def self.parse(accept_header)
      list = accept_header.to_s.split(/,/).enum_for(:each_with_index).map do |entry,index|
        AcceptType.new(entry,index += 1)
      end.sort.uniq
      # firefox (and possibly other browsers) send broken default accept headers.
      # fix them up by sorting alternate xml forms (namely application/xhtml+xml)
      # ahead of pure xml types (application/xml,text/xml).
      if app_xml = list.detect{|e| e.super_range == 'application/xml'}
        list.select{|e| e.to_s =~ /\+xml/}.each { |acc_type|
          list[list.index(acc_type)],list[list.index(app_xml)] = 
            list[list.index(app_xml)],list[list.index(acc_type)] }
      end
      list
    end
    
    def self.parse_new(accept_header)
      # FF2 is broken. If we get FF2 headers, use FF3 headers instead.
      if accept_header == "text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5"
        accept_header = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
      end
      
      headers = accept_header.split(/,/)
      idx, list = 0, []
      while idx < headers.size
        list << AcceptType.new(headers[idx], idx)
        idx += 1
      end
      list.sort
    end
  end
end

require "rubygems"
require "rbench"

RBench.run(10_000) do
  report "old_parse" do
    Merb::Responder.parse("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
  end
  
  report "new_parse" do
    Merb::Responder.parse_new("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
  end  
end