__DIR__ = File.dirname(__FILE__)

require File.join(__DIR__, "..", "..", "spec_helper")

Merb.start %W( -e test -a runner -m #{File.dirname(__FILE__) / "directory"} )