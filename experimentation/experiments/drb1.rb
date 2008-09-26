require "drb/drb"
require "irb"
require "irb/workspace"

class DRb::DRbObject
  def self.const_missing(const)
    $raw.method_missing(:instance_eval, "Object.const_get(#{const.inspect})")
  end
end

DRb.start_service
$raw = DRbObject.new_with_uri(ARGV[0])
$obj = IRB::WorkSpace.new($raw)

if @irb.nil?
  IRB.setup(nil)
  @irb = IRB::Irb.new($obj)
  IRB.conf[:MAIN_CONTEXT] = @irb.context
end

trap(:INT) { @irb.signal_handle }
catch(:IRB_EXIT) { @irb.eval_input }