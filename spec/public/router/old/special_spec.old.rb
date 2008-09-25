require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Regex-based routes" do
  
  # The following fails because named segments are no longer extracted from regular expression
  # paths. Bracket notation can still be used (eg: :action => [1]).

  it "should process a simple regex" do
    prepare_route(%r[^/foos?/(bar|baz)/:id], :controller => "foo", :action => "[1]", :id => ":id")
    route_to("/foo/bar/baz").should have_route(:controller => "foo", :action => "bar", :id => "baz")
    route_to("/foos/baz/bam").should have_route(:controller => "foo", :action => "baz", :id => "bam")
  end
  
end