begin
  require "hpricot"
  require 'merb-core/test/test_ext/hpricot'
rescue
end

require 'merb-core/test/test_ext/object'
require 'merb-core/test/test_ext/string'

module Merb; module Test; end; end

require 'merb-core/test/helpers'

if Merb.test_framework.to_s == "rspec"
  require 'merb-core/test/test_ext/rspec'
  require 'merb-core/test/matchers'
end
