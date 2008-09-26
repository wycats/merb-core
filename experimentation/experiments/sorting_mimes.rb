require "rubygems"
require "merb-core"

Merb.add_mime_type(:all,  nil,      %w[*/*])
Merb.add_mime_type(:yaml, :to_yaml, %w[application/x-yaml text/yaml], :charset => "utf-8")
Merb.add_mime_type(:text, :to_text, %w[text/plain], :charset => "utf-8")
Merb.add_mime_type(:html, :to_html, %w[text/html application/xhtml+xml application/html], :charset => "utf-8")
Merb.add_mime_type(:xml,  :to_xml,  %w[application/xml text/xml application/x-xml], {:charset => "utf-8"}, 0.9)
Merb.add_mime_type(:js,   :to_json, %w[text/javascript application/javascript application/x-javascript], :charset => "utf-8")
Merb.add_mime_type(:json, :to_json, %w[application/json text/x-json], :charset => "utf-8")

HEADER = "application/xml,application/xhtml+xml,image/png"

class Responder

  def self.parse(accept_header)
    headers = accept_header.split(/,/)

    ret = {}
    headers.each do |header|
      header =~ /\s*([^;\s]*)\s*(;\s*q=\s*([\d\.]+))?/
      quality = $3.to_f || 0 if $1 == "*/*"
      quality = quality ? quality.to_f : 1
      mime_name = Merb::ResponderMixin::MIMES[$1]
      next unless mime_name
      mime = Merb.available_mime_types[mime_name]
      ret[mime] = [mime_name, quality * mime[:default_quality]]
    end
    ret = ret.sort_by {|k,v| [-v.last]}
    ret.map {|r| r.last.first}
  end
  
end

require "pp"
pp Responder.parse(HEADER)