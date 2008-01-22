__DIR__ = File.dirname(__FILE__)

require File.join(__DIR__, "..", "..", "spec_helper")

require __DIR__ / "controllers" / "base"
require __DIR__ / "controllers" / "responder"

Merb.start %W( -e test -a runner -m #{__DIR__ / "directory"} )