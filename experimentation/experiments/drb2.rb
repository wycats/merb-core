require "drb/drb"
require "irb"
require "irb/workspace"

class Foo
  def x
    1
  end
end

drb_uri = DRb.start_service(nil, self).uri
puts drb_uri
STDIN.read