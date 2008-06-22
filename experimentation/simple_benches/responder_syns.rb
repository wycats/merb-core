require "rubygems"
require "rbench"

TYPES = {:all=>{:response_headers=>{}, :accepts=>["*/*"], :response_block=>nil, :transform_method=>nil}, :yaml=>{:response_headers=>{:charset=>"utf-8"}, :accepts=>["application/x-yaml", "text/yaml"], :response_block=>nil, :transform_method=>:to_yaml}, :text=>{:response_headers=>{:charset=>"utf-8"}, :accepts=>["text/plain"], :response_block=>nil, :transform_method=>:to_text}, :html=>{:response_headers=>{:charset=>"utf-8"}, :accepts=>["text/html", "application/xhtml+xml", "application/html"], :response_block=>nil, :transform_method=>:to_html}, :xml=>{:response_headers=>{:charset=>"utf-8"}, :accepts=>["application/xml", "text/xml", "application/x-xml"], :response_block=>nil, :transform_method=>:to_xml}, :js=>{:response_headers=>{:charset=>"utf-8"}, :accepts=>["text/javascript", "application/javascript", "application/x-javascript"], :response_block=>nil, :transform_method=>:to_json}, :json=>{:response_headers=>{:charset=>"utf-8"}, :accepts=>["application/json", "text/x-json"], :response_block=>nil, :transform_method=>:to_json}}
MIMES = {"application/json"=>:json, "application/javascript"=>:js, "text/plain"=>:text, "text/html"=>:html, "application/x-xml"=>:xml, "text/javascript"=>:js, "application/x-javascript"=>:js, "application/x-yaml"=>:yaml, "*/*"=>:all, "application/xml"=>:xml, "text/x-json"=>:json, "application/xhtml+xml"=>:html, "text/yaml"=>:yaml, "text/xml"=>:xml, "application/html"=>:html}

RBench.run(1_000_000) do
  report("old way") do
    TYPES.values.map {|e| e[:accepts] if e[:accepts].include?("text/html")}.compact.flatten
  end
  report("new way") do
    TYPES[MIMES["text/html"]][:accepts]
  end
end