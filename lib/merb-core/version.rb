module Merb
  VERSION = '0.9.6' unless defined?(Merb::VERSION)

  # Merb::RELEASE meanings:
  # 'dev'   : unreleased
  # 'pre'   : pre-release Gem candidates
  #  nil    : released
  # You should never check in to trunk with this changed.  It should
  # stay 'dev'.  Change it to nil in release tags.
  RELEASE = 'dev' unless defined?(Merb::RELEASE)
end
