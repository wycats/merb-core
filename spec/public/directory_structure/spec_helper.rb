require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

Merb.start %W( -e test -a runner -m #{File.dirname(__FILE__) / "directory"} )