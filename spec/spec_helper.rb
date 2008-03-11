$TESTING=true
require "rubygems"
require "spec"
require File.join(File.dirname(__FILE__), "..", "lib", "merb-core")

# -- Global custom matchers --

# A better +be_kind_of+ with more informative error messages.
#
# The default +be_kind_of+ just says 
#
#   "expected to return true but got false"
#
# This one says
#
#   "expected File but got Tempfile"

module Merb
  
  module Test
    
    module RspecMatchers
      
      class BeKindOf

        def initialize(expected) # + args
          @expected = expected
        end

        def matches?(target)
          @target = target
          @target.kind_of?(@expected)
        end

        def failure_message
          "expected #{@expected} but got #{@target.class}"
        end

        def negative_failure_message
          "expected #{@expected} to not be #{@target.class}"
        end

        def description
          "be_kind_of #{@target}"
        end

      end

      def be_kind_of(expected) # + args
        BeKindOf.new(expected)
      end
    end

    module Helper
      
      def running(&blk) blk; end
      
      def executing(&blk) blk; end
      
      def doing(&blk) blk; end
      
      def calling(&blk) blk; end      
    end
  end
end

Spec::Runner.configure do |config|
  config.include Merb::Test::Helper
  config.include Merb::Test::RspecMatchers
  config.include Merb::Test::RequestHelper  
end