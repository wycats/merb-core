corelib = File.dirname(__FILE__) + '/core_ext'

%w[ inflector
    class
    kernel
    object
    mash
    enumerable
    module
    string
    hash
    numeric
    symbol
    get_args
  ].each {|fn| require File.join(corelib, fn)}